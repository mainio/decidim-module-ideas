# frozen_string_literal: true

module Decidim
  module ContentRenderers
    # A renderer that searches Global IDs representing ideas in content
    # and replaces it with a link to their show page.
    #
    # e.g. gid://<APP_NAME>/Decidim::Ideas::Idea/1
    #
    # @see BaseRenderer Examples of how to use a content renderer
    class IdeaRenderer < BaseRenderer
      # Matches a global id representing a Decidim::User
      GLOBAL_ID_REGEX = %r{gid:\/\/([\w-]*\/Decidim::Ideas::Idea\/(\d+))}i.freeze

      # Replaces found Global IDs matching an existing idea with
      # a link to its show page. The Global IDs representing an
      # invalid Decidim::Ideas::Idea are replaced with '???' string.
      #
      # @return [String] the content ready to display (contains HTML)
      def render(_options = nil)
        content.gsub(GLOBAL_ID_REGEX) do |idea_gid|
          idea = GlobalID::Locator.locate(idea_gid)
          Decidim::Ideas::IdeaPresenter.new(idea).display_mention
        rescue ActiveRecord::RecordNotFound
          idea_id = idea_gid.split("/").last
          "~#{idea_id}"
        end
      end
    end
  end
end
