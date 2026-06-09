# frozen_string_literal: true

module Decidim
  module Ideas
    class IdeaVersionType < GraphQL::Schema::Object
      graphql_name "IdeaVersion"
      description "An idea version type"

      field :changeset, GraphQL::Types::JSON, null: false do
        description "Object with the changes in this version"
      end
      field :created_at, Decidim::Core::DateTimeType, null: false do
        description "The date and time this version was created"
      end
      field :editor, Decidim::Core::AuthorInterface, null: true do
        description "The editor/author of this version"
      end
      field :id, GraphQL::Types::ID, description: "ID of the idea", null: false
      field :number, GraphQL::Types::Int, null: false do
        description "The version number in the order of all versions for this object"
      end

      def number
        object.item.versions.find_index(object) + 1
      end

      def editor
        author = Decidim.traceability.version_editor(object)
        author if author.is_a?(Decidim::User) || author.is_a?(Decidim::UserGroup)
      end
    end
  end
end
