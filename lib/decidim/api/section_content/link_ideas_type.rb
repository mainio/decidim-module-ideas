# frozen_string_literal: true

module Decidim
  module Ideas
    module SectionContent
      class LinkIdeasType < GraphQL::Schema::Object
        graphql_name "PlanIdeasLinkContent"
        description "A plan content for linked ideas"

        implements Decidim::Plans::Api::ContentInterface

        field :value, [Decidim::Ideas::IdeaType], description: "The linked ideas.", null: true

        def value
          return nil unless object.body
          return nil unless object.body["idea_ids"].is_a?(Array)

          object.body["idea_ids"].map do |id|
            Decidim::Ideas::Idea.find_by(id:)
          end.compact
        end
      end
    end
  end
end
