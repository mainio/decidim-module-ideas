# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module Ideas
    module Admin
      module Filterable
        extend ActiveSupport::Concern

        included do
          include Decidim::Admin::Filterable

          helper Decidim::Ideas::Admin::FilterableHelper

          private

          def base_query
            accessible_ideas_collection
          end

          def accessible_ideas_collection
            collection
          end

          def search_field_predicate
            :id_string_or_title_cont
          end

          def filters
            [
              :is_emendation_true,
              :state_eq,
              :state_null,
              :scope_id_eq,
              :category_id_eq,
            ]
          end

          def filters_with_values
            {
              is_emendation_true: %w(true false),
              state_eq: idea_states,
              scope_id_eq: scope_ids_hash(scopes.top_level),
              category_id_eq: category_ids_hash(categories.first_class)
            }
          end

          # Can't user `super` here, because it does not belong to a superclass
          # but to a concern.
          def dynamically_translated_filters
            [:scope_id_eq, :category_id_eq]
          end

          # An Array<Symbol> of possible values for `state_eq` filter.
          # Excludes the states that cannot be filtered with the ransack predicate.
          # A link to filter by "Not answered" will be added in:
          # Decidim::Ideas::Admin::FilterableHelper#extra_dropdown_submenu_options_items
          def idea_states
            Idea::POSSIBLE_STATES.without("not_answered")
          end
        end
      end
    end
  end
end
