# frozen_string_literal: true

module Decidim
  module Ideas
    # Custom helpers, scoped to the ideas engine.
    module ControlVersionHelper
      def item_name
        versioned_resource.model_name.singular_route_key.to_sym
      end
    end
  end
end
