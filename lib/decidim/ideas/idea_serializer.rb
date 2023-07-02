# frozen_string_literal: true

module Decidim
  module Ideas
    # This class serializes a Idea so can be exported to CSV, JSON or other
    # formats.
    class IdeaSerializer < Decidim::Exporters::Serializer
      include Decidim::ApplicationHelper
      include Decidim::ResourceHelper
      include Decidim::TranslationsHelper

      # Public: Initializes the serializer with a idea.
      def initialize(idea)
        @idea = idea
      end

      # Public: Exports a hash with the serialized data for this idea.
      def serialize
        {
          id: idea.id,
          reference: idea.reference,
          participatory_space: {
            id: idea.participatory_space.id,
            url: Decidim::ResourceLocatorPresenter.new(idea.participatory_space).url
          },
          component: { id: component.id },
          area_scope: {
            id: idea.area_scope.try(:id),
            name: idea.area_scope.try(:name) || empty_translatable
          },
          category: {
            id: topcategory.try(:id),
            name: topcategory.try(:name) || empty_translatable
          },
          subcategory: {
            id: subcategory.try(:id),
            name: subcategory.try(:name) || empty_translatable
          },
          title: present(idea).title,
          body: present(idea).body,
          address: idea.address,
          coordinates: {
            available: has_coordinates?,
            latitude: coordinates[:latitude],
            longitude: coordinates[:longitude]
          },
          state: idea.state.to_s,
          answer: ensure_translatable(idea.answer),
          comments: idea.comments.count,
          attachments: idea.attachments.count,
          followers: idea.followers.count,
          published_at: idea.published_at,
          url: url,
          is_amend: idea.emendation?,
          original_idea: {
            title: idea&.amendable&.title,
            url: original_idea_url
          }
        }
      end

      private

      attr_reader :idea

      def component
        idea.component
      end

      def topcategory
        return if idea.category.blank?
        return idea.category if idea.category.parent_id.blank?

        @topcategory ||= idea.category.parent
      end

      def subcategory
        return if idea.category.blank?
        return if idea.category.parent_id.blank?

        @subcategory ||= idea.category
      end

      def has_coordinates?
        @has_coordinates ||= idea.latitude.present? && idea.longitude.present?
      end

      def coordinates
        return area_scope_coordinates unless has_coordinates?

        @coordinates ||= { latitude: idea.latitude, longitude: idea.longitude }
      end

      def area_scope_coordinates
        return @area_scope_coordinates if @area_scope_coordinates
        return blank_coordinates if idea.area_scope.blank?

        scope_coordinates = component.settings.area_scope_coordinates[idea.area_scope.id.to_s.to_sym]
        return blank_coordinates if scope_coordinates.blank?

        latlng = scope_coordinates.split(",")
        return blank_coordinates if latlng.length < 2

        @area_scope_coordinates ||= { latitude: latlng[0].to_f, longitude: latlng[1].to_f }
      end

      def blank_coordinates
        { latitude: nil, longitude: nil }
      end

      def url
        Decidim::ResourceLocatorPresenter.new(idea).url
      end

      def original_idea_url
        return unless idea.emendation? && idea.amendable.present?

        Decidim::ResourceLocatorPresenter.new(idea.amendable).url
      end
    end
  end
end
