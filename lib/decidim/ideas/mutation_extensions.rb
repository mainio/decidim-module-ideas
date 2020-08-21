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
      def self.define(type)
        type.field :idea, Decidim::Ideas::IdeaMutationType do
          description "An idea"

          argument :id, !types.ID, description: "The idea's id"

          resolve lambda { |_obj, args, _ctx|
            Idea.published.find(args[:id])
          }
        end
      end
    end
  end
end
