# frozen_string_literal: true

module Decidim
  module Ideas
    # An idea can include a vote per user.
    class IdeaVote < Ideas::ApplicationRecord
      belongs_to :idea, foreign_key: "decidim_idea_id", class_name: "Decidim::Ideas::Idea"
      belongs_to :author, foreign_key: "decidim_author_id", class_name: "Decidim::User"

      validates :idea, uniqueness: { scope: :author }
      validate :author_and_idea_same_organization
      validate :idea_not_rejected

      after_save :update_idea_votes_count
      after_destroy :update_idea_votes_count

      # Temporary votes are used when a minimum amount of votes is configured in
      # a component. They aren't taken into account unless the amount of votes
      # exceeds a threshold - meanwhile, they're marked as temporary.
      def self.temporary
        where(temporary: true)
      end

      # Final votes are votes that will be taken into account, that is, they're
      # not temporary.
      def self.final
        where(temporary: false)
      end

      private

      def update_idea_votes_count
        idea.update_votes_count
      end

      # Private: check if the idea and the author have the same organization
      def author_and_idea_same_organization
        return if !idea || !author

        errors.add(:idea, :invalid) unless author.organization == idea.organization
      end

      def idea_not_rejected
        return unless idea

        errors.add(:idea, :invalid) if idea.rejected?
      end
    end
  end
end
