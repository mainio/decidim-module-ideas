# frozen_string_literal: true

module Decidim
  module Ideas
    module Admin
      # This controller allows admins to manage ideas in a participatory process.
      class IdeasController < Admin::ApplicationController
        include Decidim::ApplicationHelper
        include Decidim::Ideas::Admin::Filterable

        helper Ideas::ApplicationHelper
        helper Decidim::Messaging::ConversationHelper
        helper_method :ideas, :query, :form_presenter, :idea_form_builder, :idea, :idea_ids
        helper Ideas::Admin::IdeaBulkActionsHelper

        def show
          @answer_form = form(Admin::IdeaAnswerForm).from_model(idea)
        end

        def new
          enforce_permission_to :create, :idea
          @form = form(Admin::IdeaForm).from_params(
            attachment: form(Decidim::AttachmentForm).from_params({})
          )
        end

        def edit
          enforce_permission_to(:edit, :idea, idea:)
          @form = form(Admin::IdeaForm).from_model(idea)
        end

        def create
          enforce_permission_to :create, :idea
          @form = form(Admin::IdeaForm).from_params(params)

          Admin::CreateIdea.call(@form, current_user) do
            on(:ok) do
              flash[:notice] = I18n.t("ideas.create.success", scope: "decidim.ideas.admin")
              redirect_to ideas_path
            end

            on(:invalid) do
              flash[:alert] = I18n.t("ideas.create.invalid", scope: "decidim.ideas.admin")
              render action: "new"
            end
          end
        end

        def publish_answers
          enforce_permission_to :publish_answers, :ideas

          Decidim::Ideas::Admin::PublishAnswers.call(current_component, current_user, idea_ids) do
            on(:invalid) do
              flash[:alert] = t(
                "ideas.publish_answers.select_an_idea",
                scope: "decidim.ideas.admin"
              )
            end

            on(:ok) do
              flash[:notice] = I18n.t("ideas.publish_answers.success", scope: "decidim")
            end
          end

          respond_to do |format|
            format.js
          end
        end

        def update
          enforce_permission_to(:edit, :idea, idea:)

          @form = form(Admin::IdeaForm).from_params(params)
          puts "***********************************************************************************"
          puts "=== IDEA PARAMS: #{params[:idea]&.to_unsafe_h} ==="
          Admin::UpdateIdea.call(@form, current_user, @idea) do
            on(:ok) do |_idea|
              flash[:notice] = t("ideas.update.success", scope: "decidim")
              redirect_to ideas_path
            end

            on(:invalid) do
              flash[:alert] = t("ideas.update.error", scope: "decidim")
              render :edit
            end
          end
        end

        private

        def collection
          @collection ||= Idea.where(component: current_component)
                              .only_amendables
                              .published
                              .not_hidden
                              .includes(:amendable, :taxonomies, :component)
        end

        def ideas
          @ideas ||= filtered_collection
        end

        def idea
          @idea ||= collection.find(params[:id])
        end

        def idea_ids
          @idea_ids ||= params[:idea_ids]
        end

        def idea_form_builder
          Decidim::Ideas::FormBuilder
        end

        def form_presenter
          @form_presenter ||= present(@form, presenter_class: Decidim::Ideas::IdeaPresenter)
        end
      end
    end
  end
end
