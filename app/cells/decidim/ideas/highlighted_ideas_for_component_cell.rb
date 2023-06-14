# frozen_string_literal: true

require "cell/partial"

module Decidim
  module Ideas
    # This cell renders the highlighted ideas for a given component.
    # It is intended to be used in the `participatory_space_highlighted_elements`
    # view hook.
    class HighlightedIdeasForComponentCell < Decidim::ViewModel
      include Decidim::ComponentPathHelper

      def show
        render unless ideas_count.zero?
      end

      private

      def ideas
        @ideas ||= Decidim::Ideas::Idea.published.not_hidden.except_withdrawn
                                       .where(component: model)
                                       .order_randomly(rand * 2 - 1)
      end

      def ideas_to_render
        @ideas_to_render ||= ideas.includes(
          [:amendable, :category, :component, :area_scope]
        ).limit(
          Decidim::Ideas.config.participatory_space_highlighted_ideas_limit
        )
      end

      def ideas_count
        @ideas_count ||= ideas.count
      end
    end
  end
end
