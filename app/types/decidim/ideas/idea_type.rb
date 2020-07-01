# frozen_string_literal: true

module Decidim
  module Ideas
    class IdeaType < GraphQL::Schema::Object
      graphql_name "Idea"
      description "An idea"

      implements Decidim::Comments::CommentableInterface
      implements Decidim::Core::CoauthorableInterface
      implements Decidim::Core::CategorizableInterface
      implements Decidim::Core::ScopableInterface
      implements Decidim::Core::AttachableInterface
      implements Decidim::Core::FingerprintInterface
      implements Decidim::Core::AmendableInterface
      implements Decidim::Core::AmendableEntityInterface
      implements Decidim::Core::TraceableInterface
      implements Decidim::Core::TimestampsInterface

      field :id, ID, null: false
      field :title, String, description: "This idea's title", null: false
      field :body, String, description: "This idea's body", null: false
      field :image, Decidim::Core::AttachmentType, "This object's attachments", null: true
      field :areaScope, Decidim::Core::ScopeApiType, method: :area_scope, null: true do
        description "The object's scope"
      end
      field :address, String, null: true do
        description "The physical address (location) of this idea"
      end
      field :coordinates, Decidim::Core::CoordinatesType, null: true do
        description "Physical coordinates for this idea"
      end

      field :reference, String, description: "This idea's unique reference", null: true
      field :state, String, description: "The answer status in which idea is in", null: true
      field :answer, Decidim::Core::TranslatedFieldType, null: true do
        description "The answer feedback for the status for this idea"
      end

      field :answeredAt, Decidim::Core::DateTimeType, method: :answered_at, null: true do
        description "The date and time this idea was answered"
      end

      field :publishedAt, Decidim::Core::DateTimeType, method: :published_at, null: true do
        description "The date and time this idea was published"
      end

      field :voteCount, Integer, resolver_method: :vote_count, null: true do
        description "The total amount of votes the idea has received"
      end

      def coordinates
        [object.latitude, object.longitude]
      end

      def vote_count
        current_component = idea.component
        idea.idea_votes_count unless current_component.current_settings.votes_hidden?
      end
    end
  end
end
