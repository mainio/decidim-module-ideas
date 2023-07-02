# frozen_string_literal: true

module Decidim
  module ContentParsers
    # A parser that searches mentions of Ideas in content.
    #
    # This parser accepts two ways for linking Ideas.
    # - Using a standard url starting with http or https.
    # - With a word starting with `~` and digits afterwards will be considered a possible mentioned idea.
    # For example `~1234`, but no `~ 1234`.
    #
    # Also fills a `Metadata#linked_ideas` attribute.
    #
    # @see BaseParser Examples of how to use a content parser
    class IdeaParser < BaseParser
      # Class used as a container for metadata
      #
      # @!attribute linked_ideas
      #   @return [Array] an array of Decidim::Ideas::Idea mentioned in content
      Metadata = Struct.new(:linked_ideas)

      # Matches a URL
      URL_REGEX_SCHEME = '(?:http(s)?:\/\/)'
      URL_REGEX_CONTENT = '[\w.-]+[\w\-\._~:\/?#\[\]@!\$&\'\(\)\*\+,;=.]+'
      URL_REGEX_END_CHAR = '[\d]'
      URL_REGEX = %r{#{URL_REGEX_SCHEME}#{URL_REGEX_CONTENT}/ideas/#{URL_REGEX_END_CHAR}+}i
      # Matches a mentioned Idea ID (~(d)+ expression)
      ID_REGEX = /~(\d+)/

      def initialize(content, context)
        super
        @metadata = Metadata.new([])
      end

      # Replaces found mentions matching an existing
      # Idea with a global id for that Idea. Other mentions found that doesn't
      # match an existing Idea are returned as they are.
      #
      # @return [String] the content with the valid mentions replaced by a global id.
      def rewrite
        rewrited_content = parse_for_urls(content)
        parse_for_ids(rewrited_content)
      end

      # (see BaseParser#metadata)
      attr_reader :metadata

      private

      def parse_for_urls(content)
        content.gsub(URL_REGEX) do |match|
          idea = idea_from_url_match(match)
          if idea
            @metadata.linked_ideas << idea.id
            idea.to_global_id
          else
            match
          end
        end
      end

      def parse_for_ids(content)
        content.gsub(ID_REGEX) do |match|
          idea = idea_from_id_match(Regexp.last_match(1))
          if idea
            @metadata.linked_ideas << idea.id
            idea.to_global_id
          else
            match
          end
        end
      end

      def idea_from_url_match(match)
        uri = URI.parse(match)
        return if uri.path.blank?

        idea_id = uri.path.split("/").last
        find_idea_by_id(idea_id)
      rescue URI::InvalidURIError
        Rails.logger.error("#{e.message}=>#{e.backtrace}")
        nil
      end

      def idea_from_id_match(match)
        idea_id = match
        find_idea_by_id(idea_id)
      end

      def find_idea_by_id(id)
        if id.present?
          spaces = Decidim.participatory_space_manifests.flat_map do |manifest|
            manifest.participatory_spaces.call(context[:current_organization]).public_spaces
          end
          components = Component.where(participatory_space: spaces).published
          Decidim::Ideas::Idea.where(component: components).find_by(id: id)
        end
      end
    end
  end
end
