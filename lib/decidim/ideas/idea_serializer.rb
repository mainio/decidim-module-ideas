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
            id: idea.category.try(:id),
            name: idea.category.try(:name) || empty_translatable
          },
          title: present(idea).title,
          body: present(idea).body,
          address: idea.address,
          latitude: idea.latitude,
          longitude: idea.longitude,
          state: idea.state.to_s,
          answer: ensure_translatable(idea.answer),
          supports: idea.idea_votes_count,
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
