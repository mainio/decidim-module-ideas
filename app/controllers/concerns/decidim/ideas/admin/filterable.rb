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

          delegate :filters, :dynamically_translated_filters, :filters_with_values, to: :filter_config

          def base_query
            return accessible_ideas_collection unless taxonomy_order_or_search?

            accessible_ideas_collection.includes(:taxonomies).joins(:taxonomies)
          end

          def accessible_ideas_collection
            collection
          end

          def search_field_predicate
            :id_string_or_title_cont
          end

          def filter_config
            @filter_config ||= Decidim::AdminFilter.new(:ideas).build_for(self)
          end

          def idea_states
            Idea::POSSIBLE_STATES.without("not_answered")
          end

          def state_eq_values
            Idea::POSSIBLE_STATES.without("not_answered")
          end

          def translated_state_eq(state)
            t("decidim.ideas.application_helper.filter_state_values.#{state}")
          end
        end
      end
    end
  end
end
