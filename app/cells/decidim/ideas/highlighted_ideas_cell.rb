# frozen_string_literal: true

require "cell/partial"

module Decidim
  module Ideas
    # This cell renders the highlighted ideas for a given participatory
    # space. It is intended to be used in the `participatory_space_highlighted_elements`
    # view hook.
    class HighlightedIdeasCell < Decidim::ViewModel
      include IdeaCellsHelper

      private

      def published_components
        Decidim::Component
          .where(
            participatory_space: model,
            manifest_name: :ideas
          )
          .published
      end
    end
  end
end
