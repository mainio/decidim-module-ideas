# frozen_string_literal: true

module Decidim
  module Ideas
    # A command with all the business logic when a user votes a idea.
    class VoteIdea < Rectify::Command
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
      # - :ok when everything is valid, together with the idea vote.
      # - :invalid if the form wasn't valid and we couldn't proceed.
      #
      # Returns nothing.
      def call
        return broadcast(:invalid) if @idea.maximum_votes_reached? && !@idea.can_accumulate_supports_beyond_threshold

        build_idea_vote
        return broadcast(:invalid) unless vote.valid?

        ActiveRecord::Base.transaction do
          @idea.with_lock do
            vote.save!
            update_temporary_votes
          end
        end

        Decidim::Gamification.increment_score(@current_user, :idea_votes)

        broadcast(:ok, vote)
      end

      attr_reader :vote

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
        return unless minimum_votes_per_user? && user_votes.count >= minimum_votes_per_user

        user_votes.each { |vote| vote.update(temporary: false) }
      end

      def user_votes
        @user_votes ||= IdeaVote.where(
          author: @current_user,
          idea: Idea.where(component: component)
        )
      end

      def build_idea_vote
        @vote = @idea.votes.build(
          author: @current_user,
          temporary: minimum_votes_per_user?
        )
      end
    end
  end
end
