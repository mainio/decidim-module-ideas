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

        @query
      end

      private

      def filter_keys_by_settings(kwargs, component)
        kwargs.select do |key, _value|
          case key
          when :vote_count
            !component.current_settings.votes_hidden?
          else
            true
          end
        end
      end
    end
  end
end
