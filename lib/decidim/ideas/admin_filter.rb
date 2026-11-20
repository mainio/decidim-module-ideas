# frozen_string_literal: true

module Decidim
  module Ideas
    class AdminFilter
      def self.register_filter!
        Decidim.admin_filter(:ideas) do |configuration|
          configuration.add_filters(
            :state_eq,
            :with_any_taxonomies,
            :taxonomies_part_of_contains
          )

          configuration.add_filters_with_values(
            state_eq: state_eq_values,
            taxonomies_part_of_contains: taxonomy_ids_hash(available_root_taxonomies)
          )

          configuration.add_dynamically_translated_filters(
            :state_eq,
            :taxonomies_part_of_contains
          )
        end
      end
    end
  end
end
