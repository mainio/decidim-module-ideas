# frozen_string_literal: true

module Decidim
  module Ideas
    class IdeasSearchResolver < GraphQL::Schema::Resolver
      include Decidim::Core::NeedsApiFilterAndOrder

      type [Decidim::Ideas::IdeaType], null: false

      argument :order, IdeaInputSort, description: "Provides several methods to order the results", required: false
      argument :filter, IdeaInputFilter, description: "Provides several methods to filter the results", required: false

      def resolve(order: nil, filter: nil)
        @query = Idea
                 .where(component: object)
                 .published
                 .not_hidden
                 .only_amendables
                 .includes(:category, :component, :area_scope)

        add_filter_keys(filter)
        if order
          order = filter_keys_by_settings(order.to_h, object)
          add_order_keys(order)
        end

        # Add default filter to avoid PostgreSQL random ordering.
        @query.order(:id)
      end

      private

      def filter_keys_by_settings(kwargs, _component)
        kwargs.select do |_key, _value|
          true
        end
      end
    end
  end
end
