# frozen_string_literal: true

require "cell/partial"

module Decidim
  module Ideas
    # This cell renders the link to the rejected emendation promoted to idea.
    class IdeaLinkToRejectedEmendationCell < IdeaLinkedResourcesCell
      private

      def linked_resource
        @linked_resource ||= model.linked_promoted_resource
      end

      def link_to_resource
        link_to resource_locator(linked_resource).path, class: "link" do
          if model.emendation?
            t("link_to_idea_from_emendation_text", scope: "decidim.ideas.ideas.show")
          else
            t("link_to_promoted_emendation_text", scope: "decidim.ideas.ideas.show")
          end
        end
      end

      def link_help_text
        if model.emendation?
          t("link_to_idea_from_emendation_help_text", scope: "decidim.ideas.ideas.show")
        else
          t("link_to_promoted_emendation_help_text", scope: "decidim.ideas.ideas.show")
        end
      end
    end
  end
end
