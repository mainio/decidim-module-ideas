# frozen_string_literal: true

module Decidim
  module Ideas
    class IdeasType < GraphQL::Schema::Object
      graphql_name "Ideas"
      description "A ideas component of a participatory space."

      implements Decidim::Core::ComponentInterface

      field :ideas, Decidim::Ideas::IdeaType.connection_type, resolver: Decidim::Ideas::IdeasSearchResolver, description: "List all ideas", null: true

      field :idea, Decidim::Ideas::IdeaType, description: "Finds one idea", null: true do
        argument :id, GraphQL::Types::ID, required: true
      end

      def idea(id:)
        IdeasTypeHelper.base_scope(object).find_by(id:)
      end
    end

    module IdeasTypeHelper
      include Decidim::Core::NeedsApiFilterAndOrder

      def self.base_scope(component)
        Idea
          .where(component:)
          .published
          .not_hidden
          .only_amendables
          .includes(:category, :component, :area_scope)
      end
    end
  end
end
