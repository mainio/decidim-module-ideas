# frozen_string_literal: true

module Decidim
  module Ideas
    # A command with all the business logic when a user unvotes a idea.
    class UnvoteIdea < Rectify::Command
      # Public: Initializes the command.
      #
      # idea     - A Decidim::Ideas::Idea object.
      # current_user - The current user.
      def initialize(idea, current_user)
        @idea = idea
        @current_user = current_user
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when everything is valid, together with the idea.
      # - :invalid if the form wasn't valid and we couldn't proceed.
      #
      # Returns nothing.
      def call
        ActiveRecord::Base.transaction do
          IdeaVote.where(
            author: @current_user,
            idea: @idea
          ).destroy_all

          update_temporary_votes
        end

        Decidim::Gamification.decrement_score(@current_user, :idea_votes)

        broadcast(:ok, @idea)
      end

      private

      def component
        @component ||= @idea.component
      end

      def minimum_votes_per_user
        component.settings.minimum_votes_per_user
      end

      def minimum_votes_per_user?
        minimum_votes_per_user.positive?
      end

      def update_temporary_votes
        return unless minimum_votes_per_user? && user_votes.count < minimum_votes_per_user

        user_votes.each { |vote| vote.update(temporary: true) }
      end

      def user_votes
        @user_votes ||= IdeaVote.where(
          author: @current_user,
          idea: Idea.where(component: component)
        )
      end
    end
  end
end
