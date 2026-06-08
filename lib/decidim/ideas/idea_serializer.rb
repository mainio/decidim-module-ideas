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
          taxonomies:,
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
          url:,
          is_amend: idea.emendation?,
          original_idea: {
            title: idea&.amendable&.title,
            url: original_idea_url
          }
        }
      end

      private

      attr_reader :idea
      alias resource idea

      def component
        idea.component
      end

      def has_coordinates?
        @has_coordinates ||= idea.latitude.present? && idea.longitude.present?
      end

      def coordinates
        return area_taxonomy_coordinates unless has_coordinates?

        @coordinates ||= { latitude: idea.latitude, longitude: idea.longitude }
      end

      def area_taxonomy_coordinates
        @area_taxonomy_coordinates ||= compute_area_taxonomy_coordinates
      end

      def compute_area_taxonomy_coordinates
        return blank_coordinates unless area_taxonomy_filter_id

        area_taxonomy = idea.taxonomies.find { |t| area_taxonomy_ids.include?(t.id) }
        return blank_coordinates unless area_taxonomy

        scope_coordinates = component.settings.area_scope_coordinates[:"#{area_taxonomy.id}"]
        return blank_coordinates if scope_coordinates.blank?

        latlng = scope_coordinates.split(",")
        return blank_coordinates if latlng.length < 2

        { latitude: latlng[0].to_f, longitude: latlng[1].to_f }
      end

      def area_taxonomy_filter_id
        @area_taxonomy_filter_id ||= component.settings.area_taxonomy_filter_id
      end

      def area_taxonomy_ids
        @area_taxonomy_ids ||= begin
          filter = Decidim::TaxonomyFilter.find_by(id: area_taxonomy_filter_id)
          if filter
            filter.taxonomies.values.flat_map { |node| collect_taxonomy_ids(node) }
          else
            []
          end
        end
      end

      def collect_taxonomy_ids(node)
        ids = [node[:taxonomy].id]
        ids + node[:children].values.flat_map { |child_node| collect_taxonomy_ids(child_node) }
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