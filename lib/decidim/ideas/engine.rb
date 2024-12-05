# frozen_string_literal: true

require "kaminari"
require "ransack"
require "cells/rails"
require "cells-erb"
require "cell/partial"

module Decidim
  module Ideas
    # This is the engine that runs on the public interface of `decidim-ideas`.
    # It mostly handles rendering the created page associated to a participatory
    # process.
    class Engine < ::Rails::Engine
      isolate_namespace Decidim::Ideas

      routes do
        resources :ideas, except: [:destroy] do
          member do
            get :edit_draft
            patch :update_draft
            get :preview
            post :publish
            delete :destroy_draft
            put :withdraw
          end
          collection do
            get :search_ideas
            resources :info, only: [:show], param: :section
            resource :geocoding, only: [:create] do
              collection do
                post :reverse
              end
            end
          end
          resources :versions, only: [:show, :index]
        end

        root to: "ideas#index"
      end

      initializer "decidim_plans.webpacker.assets_path" do
        Decidim.register_assets_path File.expand_path("app/packs", root)
      end

      initializer "decidim_ideas.content_processors" do |_app|
        Decidim.configure do |config|
          config.content_processors += [:idea]
        end
      end

      initializer "decidim_ideas.mutation_extensions" do
        Decidim::Api::MutationType.include(Decidim::Ideas::MutationExtensions)
      end

      initializer "decidim_ideas.mentions_listener" do
        Decidim::Comments::CommentCreation.subscribe do |data|
          ideas = data.dig(:metadatas, :idea).try(:linked_ideas)
          Decidim::Ideas::NotifyIdeasMentionedJob.perform_later(data[:comment_id], ideas) if ideas
        end
      end

      # Subscribes to ActiveSupport::Notifications that may affect an Idea.
      initializer "decidim_ideas.subscribe_to_events" do
        # when an idea is linked from a result
        event_name = "decidim.resourceable.included_ideas.created"
        ActiveSupport::Notifications.subscribe event_name do |_name, _started, _finished, _unique_id, data|
          payload = data[:this]
          if payload[:from_type] == Decidim::Accountability::Result.name && payload[:to_type] == Idea.name
            idea = Idea.find(payload[:to_id])
            idea.update(state: "accepted", state_published_at: Time.current)
          end
        end
      end

      initializer "decidim_ideas.add_cells_view_paths" do
        Cell::ViewModel.view_paths << File.expand_path("#{Decidim::Ideas::Engine.root}/app/cells")
        Cell::ViewModel.view_paths << File.expand_path("#{Decidim::Ideas::Engine.root}/app/views") # for idea partials
      end

      initializer "decidim_ideas.add_badges" do
        Decidim::Gamification.register_badge(:ideas) do |badge|
          badge.levels = [1, 5, 10, 30, 60]

          badge.valid_for = [:user, :user_group]

          badge.reset = lambda { |model|
            case model
            when User
              Decidim::Coauthorship.where(
                coauthorable_type: "Decidim::Ideas::Idea",
                author: model,
                user_group: nil
              ).count
            when UserGroup
              Decidim::Coauthorship.where(
                coauthorable_type: "Decidim::Ideas::Idea",
                user_group: model
              ).count
            end
          }
        end

        Decidim::Gamification.register_badge(:accepted_ideas) do |badge|
          badge.levels = [1, 5, 15, 30, 50]

          badge.valid_for = [:user, :user_group]

          badge.reset = lambda { |model|
            idea_ids = case model
                       when User
                         Decidim::Coauthorship.where(
                           coauthorable_type: "Decidim::Ideas::Idea",
                           author: model,
                           user_group: nil
                         ).select(:coauthorable_id)
                       when UserGroup
                         Decidim::Coauthorship.where(
                           coauthorable_type: "Decidim::Ideas::Idea",
                           user_group: model
                         ).select(:coauthorable_id)
                       end

            Decidim::Ideas::Idea.where(id: idea_ids).accepted.count
          }
        end
      end

      initializer "decidim_ideas.register_metrics" do
        Decidim.metrics_registry.register(:ideas) do |metric_registry|
          metric_registry.manager_class = "Decidim::Ideas::Metrics::IdeasMetricManage"

          metric_registry.settings do |settings|
            settings.attribute :highlighted, type: :boolean, default: true
            settings.attribute :scopes, type: :array, default: %w(home participatory_process)
            settings.attribute :weight, type: :integer, default: 2
            settings.attribute :stat_block, type: :string, default: "medium"
          end
        end

        Decidim.metrics_registry.register(:accepted_ideas) do |metric_registry|
          metric_registry.manager_class = "Decidim::Ideas::Metrics::AcceptedIdeasMetricManage"

          metric_registry.settings do |settings|
            settings.attribute :highlighted, type: :boolean, default: false
            settings.attribute :scopes, type: :array, default: %w(home participatory_process)
            settings.attribute :weight, type: :integer, default: 3
            settings.attribute :stat_block, type: :string, default: "small"
          end
        end

        Decidim.metrics_operation.register(:participants, :ideas) do |metric_operation|
          metric_operation.manager_class = "Decidim::Ideas::Metrics::IdeaParticipantsMetricMeasure"
        end

        Decidim.metrics_operation.register(:followers, :ideas) do |metric_operation|
          metric_operation.manager_class = "Decidim::Ideas::Metrics::IdeaFollowersMetricMeasure"
        end
      end

      initializer "decidim_ideas.budgets_integration", after: "decidim_plans.register_section_types" do
        next unless Decidim.const_defined?("Budgets")

        Decidim::Ideas::ResourceLinkSubject.class_eval do
          possible_types(Decidim::Budgets::ProjectType)
        end
      end

      initializer "decidim_ideas.accountability_integration", after: "decidim_plans.register_section_types" do
        next unless Decidim.const_defined?("Accountability")

        Decidim::Ideas::ResourceLinkSubject.class_eval do
          possible_types(Decidim::Accountability::ResultType)
        end
      end

      initializer "decidim_ideas.plans_integration", after: "decidim_plans.register_section_types" do
        next unless Decidim.const_defined?("Plans")

        require "decidim/plans/api"

        Decidim::Ideas::ResourceLinkSubject.class_eval do
          possible_types(Decidim::Plans::PlanType)
        end
        Decidim::Plans::ContentSubject.class_eval do
          possible_types(Decidim::Ideas::SectionContent::LinkIdeasType)
        end
        Decidim::Plans::ResourceLinkSubject.class_eval do
          possible_types(Decidim::Ideas::IdeaType)
        end
        Decidim::Plans::ContentMutationAttributes.class_eval do
          argument(:ideas, ::Decidim::Ideas::ContentMutation::FieldIdeasAttributes, required: false)
        end

        registry = Decidim::Plans.section_types
        registry.register(:link_ideas) do |type|
          type.edit_cell = "decidim/ideas/section_type_edit/link_ideas"
          type.display_cell = "decidim/ideas/section_type_display/link_ideas"
          type.content_form_class_name = "Decidim::Ideas::ContentData::LinkIdeasForm"
          type.content_control_class_name = "Decidim::Ideas::SectionControl::LinkIdeas"
          type.api_type_class_name = "Decidim::Ideas::SectionContent::LinkIdeasType"
        end
        registry.register(:link_ideas_inline) do |type|
          type.edit_cell = "decidim/ideas/section_type_edit/link_ideas_inline"
          type.display_cell = "decidim/ideas/section_type_display/link_ideas"
          type.content_form_class_name = "Decidim::Ideas::ContentData::LinkIdeasForm"
          type.content_control_class_name = "Decidim::Ideas::SectionControl::LinkIdeas"
          type.api_type_class_name = "Decidim::Ideas::SectionContent::LinkIdeasType"
        end
      end

      initializer "decidim_ideas.api_linking_resources", before: :finisher_hook do
        Decidim::Ideas::IdeaType.add_linking_resources_field
      end

      initializer "decidim_ideas.overrides", after: "decidim.action_controller" do |app|
        app.config.to_prepare do
          Decidim::Admin::FilterableHelper.include Decidim::Ideas::Admin::FilterableHelperOverride
        end
      end
    end
  end
end
