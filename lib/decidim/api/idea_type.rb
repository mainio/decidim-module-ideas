# frozen_string_literal: true

module Decidim
  module Ideas
    class IdeaType < GraphQL::Schema::Object
      graphql_name "Idea"
      description "An idea"

      implements Decidim::Comments::CommentableInterface
      implements Decidim::Core::CoauthorableInterface
      implements Decidim::Core::CategorizableInterface
      # implements Decidim::Core::ScopableInterface
      implements Decidim::Core::FingerprintInterface
      implements Decidim::Core::AmendableInterface
      implements Decidim::Core::AmendableEntityInterface
      implements Decidim::Core::TimestampsInterface
      implements Decidim::Favorites::Api::FavoritesInterface

      field :id, GraphQL::Types::ID, null: false
      field :title, GraphQL::Types::String, description: "This idea's title", null: false
      field :body, GraphQL::Types::String, description: "This idea's body", null: false
      field :image, Decidim::Core::AttachmentType, "This object's attachments", null: true
      field :attachments, [Decidim::Core::AttachmentType], "This object's attachments", null: true, method: :actual_attachments
      field :area_scope, Decidim::Core::ScopeApiType, null: true do
        description "The object's scope"
      end
      field :address, GraphQL::Types::String, null: true do
        description "The physical address (location) of this idea"
      end
      field :coordinates, Decidim::Core::CoordinatesType, null: true do
        description "Physical coordinates for this idea"
      end

      field :reference, GraphQL::Types::String, description: "This idea's unique reference", null: true
      field :state, GraphQL::Types::String, description: "The answer status in which idea is in (null|accepted|rejected|evaluating|withdrawn)", null: true
      field :answer, Decidim::Core::TranslatedFieldType, null: true do
        description "The answer feedback for the status for this idea"
      end

      field :answered_at, Decidim::Core::DateTimeType, null: true do
        description "The date and time this idea was answered"
      end

      field :published_at, Decidim::Core::DateTimeType, null: true do
        description "The date and time this idea was published"
      end

      # Modifies Decidim::Core::TraceableInterface because we use different
      # version type in order to add our customizations.
      field :versions_count, GraphQL::Types::Int, null: false do
        description "Total number of versions"
      end
      field :versions, [Decidim::Ideas::IdeaVersionType], null: false do
        description "This object's versions"
      end

      def self.add_linking_resources_field
        return unless Decidim::Ideas::ResourceLinkSubject.possible_types.any?

        # These are the resources that are linked from the related object to the
        # idea.
        field(
          :linking_resources,
          [Decidim::Ideas::ResourceLinkSubject],
          description: "The linked resources for this idea.",
          null: true
        )
      end

      def coordinates
        [object.latitude, object.longitude]
      end

      # rubocop:disable Metrics/CyclomaticComplexity
      def linking_resources
        resources = object.resource_links_to.map(&:from).reject do |resource|
          resource.nil? ||
            (resource.respond_to?(:published?) && !resource.published?) ||
            (resource.respond_to?(:hidden?) && resource.hidden?) ||
            (resource.respond_to?(:withdrawn?) && resource.withdrawn?)
        end
        return nil unless resources.any?

        resources
      end
      # rubocop:enable Metrics/CyclomaticComplexity
    end
  end
end
