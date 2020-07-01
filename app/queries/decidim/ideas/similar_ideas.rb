# frozen_string_literal: true

module Decidim
  module Ideas
    # Class used to retrieve similar ideas.
    class SimilarIdeas < Rectify::Query
      include Decidim::TranslationsHelper

      # Syntactic sugar to initialize the class and return the queried objects.
      #
      # components - Decidim::CurrentComponent
      # idea - Decidim::Ideas::Idea
      def self.for(components, idea)
        new(components, idea).query
      end

      # Initializes the class.
      #
      # components - Decidim::CurrentComponent
      # idea - Decidim::Ideas::Idea
      def initialize(components, idea)
        @components = components
        @idea = idea
      end

      # Retrieves similar ideas
      def query
        Decidim::Ideas::Idea
          .where(component: @components)
          .published
          .where(
            "GREATEST(#{title_similarity}, #{body_similarity}) >= ?",
            @idea.title,
            @idea.body,
            Decidim::Ideas.similarity_threshold
          )
          .limit(Decidim::Ideas.similarity_limit)
      end

      private

      def title_similarity
        "similarity(title, ?)"
      end

      def body_similarity
        "similarity(body, ?)"
      end
    end
  end
end
