# frozen_string_literal: true

module Decidim
  module Ideas
    class PublishIdeaEvent < Decidim::Events::SimpleEvent
      include Decidim::Events::CoauthorEvent

      def resource_text
        resource.body
      end

      private

      def i18n_scope
        return super unless participatory_space_event?

        "decidim.events.ideas.idea_published_for_space"
      end

      def participatory_space_event?
        extra[:participatory_space]
      end
    end
  end
end
