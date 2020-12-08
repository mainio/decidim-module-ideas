# frozen_string_literal: true

module Decidim
  module Ideas
    module ContentMutation
      class FieldIdeasAttributes < GraphQL::Schema::InputObject
        graphql_name "PlanIdeasFieldAttributes"
        description "A plan attributes for linked ideas field"

        argument :ids, [ID], required: true

        def to_h
          existing_ids = ids.map do |id|
            idea = Decidim::Ideas::Idea.find_by(id: id)
            idea&.id
          end

          { "idea_ids" => existing_ids.compact }
        end
      end
    end
  end
end
