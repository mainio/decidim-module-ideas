# frozen_string_literal: true

module Decidim
  module Ideas
    # The LinkedResourceSubject class creates the linked resource information
    # for the idea objects.
    class ResourceLinkSubject < GraphQL::Schema::Union
      graphql_name "IdeaResourceLinkSubject"
      description "An idea linked resource detailed values"

      possible_types(Decidim::Plans::PlanType)

      def self.resolve_type(object, _context)
        "#{object.class}Type".constantize
      end
    end
  end
end
