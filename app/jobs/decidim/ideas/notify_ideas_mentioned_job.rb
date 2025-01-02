# frozen_string_literal: true

module Decidim
  module Ideas
    class NotifyIdeasMentionedJob < ApplicationJob
      def perform(comment_id, linked_ideas)
        comment = Decidim::Comments::Comment.find(comment_id)

        linked_ideas.each do |idea_id|
          idea = Idea.find(idea_id)
          affected_users = idea.notifiable_identities

          Decidim::EventsManager.publish(
            event: "decidim.events.ideas.idea_mentioned",
            event_class: Decidim::Ideas::IdeaMentionedEvent,
            resource: comment.root_commentable,
            affected_users:,
            extra: {
              comment_id: comment.id,
              mentioned_idea_id: idea_id
            }
          )
        end
      end
    end
  end
end
