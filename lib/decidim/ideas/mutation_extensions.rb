# frozen_string_literal: true

module Decidim
  module Ideas
    # This module's job is to extend the API with custom fields related to
    # decidim-ideas.
    module MutationExtensions
      # Public: Extends a type with `decidim-ideas`'s fields.
      #
      # type - A GraphQL::BaseType to extend.
      #
      # Returns nothing.
      def self.included(type)
        type.field :idea, Decidim::Ideas::IdeaMutationType, null: false do
          description "An idea"

          argument :id, GraphQL::Types::ID, description: "The idea's id", required: true
        end
      end

      def idea(id:)
        Idea.published.find(id)
      end
    end
  end
end
