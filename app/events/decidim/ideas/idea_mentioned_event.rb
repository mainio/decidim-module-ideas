# frozen-string_literal: true

module Decidim
  module Ideas
    class IdeaMentionedEvent < Decidim::Events::SimpleEvent
      include Decidim::ApplicationHelper

      i18n_attributes :mentioned_idea_title

      private

      def mentioned_idea_title
        present(mentioned_idea).title
      end

      def mentioned_idea
        @mentioned_idea ||= Decidim::Ideas::Idea.find(extra[:mentioned_idea_id])
      end
    end
  end
end
