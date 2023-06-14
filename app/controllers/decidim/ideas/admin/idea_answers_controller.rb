# frozen_string_literal: true

module Decidim
  module Ideas
    module Admin
      # This controller allows admins to answer ideas in a participatory process.
      class IdeaAnswersController < Admin::ApplicationController
        helper_method :idea

        helper Ideas::ApplicationHelper
        helper Decidim::Ideas::Admin::IdeasHelper
        helper Decidim::Messaging::ConversationHelper

        def edit
          enforce_permission_to :create, :idea_answer, idea: idea
          @form = form(Admin::IdeaAnswerForm).from_model(idea)
        end

        def update
          enforce_permission_to :create, :idea_answer, idea: idea
          @answer_form = form(Admin::IdeaAnswerForm).from_params(params)

          Admin::AnswerIdea.call(@answer_form, idea) do
            on(:ok) do
              flash[:notice] = I18n.t("ideas.answer.success", scope: "decidim.ideas.admin")
              redirect_to Decidim::ResourceLocatorPresenter.new(idea).index
            end

            on(:invalid) do
              flash.keep[:alert] = I18n.t("ideas.answer.invalid", scope: "decidim.ideas.admin")
              render template: "decidim/ideas/admin/ideas/show"
            end
          end
        end

        private

        def skip_manage_component_permission
          true
        end

        def idea
          @idea ||= Idea.where(component: current_component).find(params[:id])
        end
      end
    end
  end
end
