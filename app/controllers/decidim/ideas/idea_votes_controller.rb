# frozen_string_literal: true

module Decidim
  module Ideas
    class IdeaVotesController < Decidim::Ideas::ApplicationController
      include IdeaVotesHelper
      include Rectify::ControllerHelpers

      helper_method :idea

      before_action :authenticate_user!

      def create
        enforce_permission_to :vote, :idea, idea: idea
        @from_ideas_list = params[:from_ideas_list] == "true"

        VoteIdea.call(idea, current_user) do
          on(:ok) do
            idea.reload

            ideas = IdeaVote.where(
              author: current_user,
              idea: Idea.where(component: current_component)
            ).map(&:idea)

            expose(ideas: ideas)
            render :update_buttons_and_counters
          end

          on(:invalid) do
            render json: { error: I18n.t("idea_votes.create.error", scope: "decidim.ideas") }, status: :unprocessable_entity
          end
        end
      end

      def destroy
        enforce_permission_to :unvote, :idea, idea: idea
        @from_ideas_list = params[:from_ideas_list] == "true"

        UnvoteIdea.call(idea, current_user) do
          on(:ok) do
            idea.reload

            ideas = IdeaVote.where(
              author: current_user,
              idea: Idea.where(component: current_component)
            ).map(&:idea)

            expose(ideas: ideas + [idea])
            render :update_buttons_and_counters
          end
        end
      end

      private

      def idea
        @idea ||= Idea.where(component: current_component).find(params[:idea_id])
      end
    end
  end
end
