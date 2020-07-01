# frozen_string_literal: true

module Decidim
  module Ideas
    module Admin
      # This controller allows admins to manage ideas in a participatory process.
      class IdeasController < Admin::ApplicationController
        include Decidim::ApplicationHelper
        include Decidim::Ideas::Admin::Filterable

        helper Ideas::ApplicationHelper
        helper Decidim::Ideas::Admin::IdeaRankingsHelper
        helper Decidim::Messaging::ConversationHelper
        helper_method :ideas, :query, :form_presenter, :idea, :idea_ids
        helper Ideas::Admin::IdeaBulkActionsHelper

        def show
          @answer_form = form(Admin::IdeaAnswerForm).from_model(idea)
        end

        def new
          enforce_permission_to :create, :idea
          @form = form(Admin::IdeaForm).from_params(
            attachment: form(AttachmentForm).from_params({})
          )
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
              flash.now[:alert] = I18n.t("ideas.create.invalid", scope: "decidim.ideas.admin")
              render action: "new"
            end
          end
        end

        def update_category
          enforce_permission_to :update, :idea_category

          Admin::UpdateIdeaCategory.call(params[:category][:id], idea_ids) do
            on(:invalid_category) do
              flash.now[:error] = I18n.t(
                "ideas.update_category.select_a_category",
                scope: "decidim.ideas.admin"
              )
            end

            on(:invalid_idea_ids) do
              flash.now[:alert] = I18n.t(
                "ideas.update_category.select_an_idea",
                scope: "decidim.ideas.admin"
              )
            end

            on(:update_ideas_category) do
              flash.now[:notice] = update_ideas_bulk_response_successful(@response, :category)
              flash.now[:alert] = update_ideas_bulk_response_errored(@response, :category)
            end
            respond_to do |format|
              format.js
            end
          end
        end

        def publish_answers
          enforce_permission_to :publish_answers, :ideas

          Decidim::Ideas::Admin::PublishAnswers.call(current_component, current_user, idea_ids) do
            on(:invalid) do
              flash.now[:alert] = t(
                "ideas.publish_answers.select_an_idea",
                scope: "decidim.ideas.admin"
              )
            end

            on(:ok) do
              flash.now[:notice] = I18n.t("ideas.publish_answers.success", scope: "decidim")
            end
          end

          respond_to do |format|
            format.js
          end
        end

        def update_area_scope
          enforce_permission_to :update, :idea_scope

          Admin::UpdateIdeaAreaScope.call(params[:scope_id], idea_ids) do
            on(:invalid_scope) do
              flash.now[:error] = t(
                "ideas.update_scope.select_a_scope",
                scope: "decidim.ideas.admin"
              )
            end

            on(:invalid_idea_ids) do
              flash.now[:alert] = t(
                "ideas.update_scope.select_an_idea",
                scope: "decidim.ideas.admin"
              )
            end

            on(:update_ideas_scope) do
              flash.now[:notice] = update_ideas_bulk_response_successful(@response, :scope)
              flash.now[:alert] = update_ideas_bulk_response_errored(@response, :scope)
            end

            respond_to do |format|
              format.js
            end
          end
        end

        def edit
          enforce_permission_to :edit, :idea, idea: idea
          @form = form(Admin::IdeaForm).from_model(idea)
          @form.attachment = form(AttachmentForm).from_params({})
        end

        def update
          enforce_permission_to :edit, :idea, idea: idea

          @form = form(Admin::IdeaForm).from_params(params)
          Admin::UpdateIdea.call(@form, @idea) do
            on(:ok) do |_idea|
              flash[:notice] = t("ideas.update.success", scope: "decidim")
              redirect_to ideas_path
            end

            on(:invalid) do
              flash.now[:alert] = t("ideas.update.error", scope: "decidim")
              render :edit
            end
          end
        end

        private

        def collection
          @collection ||= Idea.where(component: current_component).published
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

        def update_ideas_bulk_response_successful(response, subject)
          return if response[:successful].blank?

          if subject == :category
            t(
              "ideas.update_category.success",
              subject_name: response[:subject_name],
              ideas: response[:successful].to_sentence,
              scope: "decidim.ideas.admin"
            )
          elsif subject == :scope
            t(
              "ideas.update_scope.success",
              subject_name: response[:subject_name],
              ideas: response[:successful].to_sentence,
              scope: "decidim.ideas.admin"
            )
          end
        end

        def update_ideas_bulk_response_errored(response, subject)
          return if response[:errored].blank?

          if subject == :category
            t(
              "ideas.update_category.invalid",
              subject_name: response[:subject_name],
              ideas: response[:errored].to_sentence,
              scope: "decidim.ideas.admin"
            )
          elsif subject == :scope
            t(
              "ideas.update_scope.invalid",
              subject_name: response[:subject_name],
              ideas: response[:errored].to_sentence,
              scope: "decidim.ideas.admin"
            )
          end
        end

        def form_presenter
          @form_presenter ||= present(@form, presenter_class: Decidim::Ideas::IdeaPresenter)
        end
      end
    end
  end
end
