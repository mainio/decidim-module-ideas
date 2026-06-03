# frozen_string_literal: true

module Decidim
  module Ideas
    class AdminFilter
      def self.register_filter!
        Decidim.admin_filter(:ideas) do |configuration|
          configuration.add_filters(
            :state_eq,
            :with_any_taxonomies
          )
        end
      end
    end
  end
end