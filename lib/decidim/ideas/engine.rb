# frozen_string_literal: true

require "kaminari"
require "social-share-button"
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
            resources :info, only: [:show], param: :section
            resource :geocoding, only: [:create] do
              collection do
                post :reverse
              end
            end
          end
          resource :idea_vote, only: [:create, :destroy]
          resources :versions, only: [:show, :index]
        end

        root to: "ideas#index"
      end

      initializer "decidim_ideas.assets" do |app|
        app.config.assets.precompile += %w(decidim_ideas_manifest.js
                                           decidim/ideas/idea_form.js
                                           decidim/ideas/ideas_list.js
                                           decidim/ideas/utils.js)
      end

      initializer "decidim_ideas.content_processors" do |_app|
        Decidim.configure do |config|
          config.content_processors += [:idea]
        end
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
            if model.is_a?(User)
              Decidim::Coauthorship.where(
                coauthorable_type: "Decidim::Ideas::Idea",
                author: model,
                user_group: nil
              ).count
            elsif model.is_a?(UserGroup)
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
            idea_ids = begin
              if model.is_a?(User)
                Decidim::Coauthorship.where(
                  coauthorable_type: "Decidim::Ideas::Idea",
                  author: model,
                  user_group: nil
                ).select(:coauthorable_id)
              elsif model.is_a?(UserGroup)
                Decidim::Coauthorship.where(
                  coauthorable_type: "Decidim::Ideas::Idea",
                  user_group: model
                ).select(:coauthorable_id)
              end
            end

            Decidim::Ideas::Idea.where(id: idea_ids).accepted.count
          }
        end

        Decidim::Gamification.register_badge(:idea_votes) do |badge|
          badge.levels = [5, 15, 50, 100, 500]

          badge.reset = lambda { |user|
            Decidim::Ideas::IdeaVote.where(author: user).select(:decidim_idea_id).distinct.count
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

        Decidim.metrics_registry.register(:idea_votes) do |metric_registry|
          metric_registry.manager_class = "Decidim::Ideas::Metrics::VotesMetricManage"

          metric_registry.settings do |settings|
            settings.attribute :highlighted, type: :boolean, default: true
            settings.attribute :scopes, type: :array, default: %w(home participatory_process)
            settings.attribute :weight, type: :integer, default: 3
            settings.attribute :stat_block, type: :string, default: "medium"
          end
        end

        Decidim.metrics_operation.register(:participants, :ideas) do |metric_operation|
          metric_operation.manager_class = "Decidim::Ideas::Metrics::IdeaParticipantsMetricMeasure"
        end

        Decidim.metrics_operation.register(:followers, :ideas) do |metric_operation|
          metric_operation.manager_class = "Decidim::Ideas::Metrics::IdeaFollowersMetricMeasure"
        end
      end
    end
  end
end
