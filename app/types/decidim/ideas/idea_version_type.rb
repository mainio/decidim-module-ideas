# frozen_string_literal: true

module Decidim
  module Ideas
    class IdeaVersionType < GraphQL::Schema::Object
      graphql_name "IdeaVersion"
      description "An idea version type"

      field :id, ID, null: false
      field :number, Integer, null: false do
        description "The version number in the order of all versions for this object"
      end
      field :createdAt, Decidim::Core::DateTimeType , method: :created_at, null: false do
        description "The date and time this version was created"
      end
      field :editor, Decidim::Core::AuthorInterface, null: true do
        description "The editor/author of this version"
      end
      field :changeset, GraphQL::Types::JSON, null: false do
        description "Object with the changes in this version"
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
