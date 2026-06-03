# frozen_string_literal: true

require "cell/partial"

module Decidim
  module Ideas
    # This cell renders a idea with its G-size card.
    class IdeaGCell < Decidim::CardGCell
      include IdeaCellsHelper

      property :area_scope, :answered?

      def badge
        render if has_badge?
      end

      def resource_utm_params
        return {} unless context[:utm_params]

        context[:utm_params].transform_keys do |key|
          "utm_#{key}"
        end
      end

      private

      def card_wrapper
        wrapper_options = { class: "card", aria: { label: t(".card_label", title:) } }
        if has_link_to_resource?
          link_to resource_path, **wrapper_options do
            yield
          end
        else
          aria_options = { role: "region" }
          content_tag :div, **aria_options.merge(wrapper_options) do
            yield
          end
        end
      end

      def preview?
        options[:preview]
      end

      def render_column?
        !context[:no_column].presence
      end

      def show_favorite_button?
        !context[:disable_favorite].presence
      end

      # Don't display the authors on the card.
      def has_authors?
        false
      end

      def title
        decidim_html_escape(present(model).title)
      end

      def show_space?
        (context[:show_space].presence || options[:show_space].presence) && resource.respond_to?(:participatory_space) && resource.participatory_space.present?
      end

      def participatory_space_title
        return unless show_space?

        @participatory_space ||= decidim_html_escape(translated_attribute(resource.participatory_space.title))
      end

      def body
        decidim_sanitize(present(model).body)
      end

      def taxonomies
        @taxonomies ||= model.taxonomies
      end

      def full_taxonimies
        taxonomies.map do |t|
          parts = []
          parts << translated_attribute(t.parent.name) if t.parent
          parts << decidim_sanitize(translated_attribute(t.name))
          { taxonomy: t, full_taxonomy: parts.join(" - ") }
        end
      end

      # Returns an array of CSS class strings, one per taxonomy.
      def taxonomy_classes
        return [] unless has_taxonomies?

        taxonomies.map { |t| "card__category--#{t.id}" }
      end

      def has_state?
        model.published?
      end

      def has_taxonomies?
        taxonomies.any?
      end

      def has_badge?
        published_state? || withdrawn?
      end

      def has_link_to_resource?
        model.published?
      end

      def has_footer?
        true
      end

      def description
        strip_tags(body).truncate(100, separator: /\s/)
      end

      def badge_classes
        return super unless options[:full_badge]

        state_classes.push("label", "idea-status").join(" ")
      end

      def statuses
        return [] if preview?
        return [:comments_count] if model.draft?

        [:comments_count, :favorites_count]
      end

      def comments_count_status
        render_comments_count
      end

      def creation_date_status
        l(model.published_at.to_date, format: :decidim_short)
      end

      def favorites_count_status
        cell("decidim/favorites/favorites_count", model)
      end

      # Returns an array of hashes with id and name for each taxonomy.
      def taxonomy_labels
        return [] unless has_taxonomies?

        taxonomies.map { |t| { id: t.id, name: translated_attribute(t.name) } }
      end

      def taxonomy_icons
        return [] unless has_taxonomies?

        taxonomies.filter_map do |t|
          next unless t.respond_to?(:taxonomy_icon) && t.taxonomy_icon&.attached?

          {
            taxonomy: t,
            icon: content_tag(:span, class: "card__category__icon", "aria-hidden": true) do
              image_tag(t.attached_uploader(:taxonomy_icon).url, alt: translated_attribute(t.name))
            end
          }
        end
      end

      # Returns an array of style hashes for taxonomies that have a color defined.
      # Each hash contains :taxonomy (the taxonomy object) and :style (the inline CSS string).
      def taxonomy_styles
        return [] unless has_taxonomies?

        taxonomies.filter_map do |t|
          next unless t.respond_to?(:color) && t.color.present?

          { taxonomy: t, style: "background-color:#{t.color};" }
        end
      end

      def progress_bar_progress
        0
      end

      def progress_bar_total
        0
      end

      def has_image?
        model.image && model.image.attached? && model.image.file.content_type.start_with?("image") && model.component.settings.image_allowed?
      end

      def resource_image_path
        return model.image.attached_uploader(:file).variant_url(resource_image_variant) if has_image?

        taxonomy_image_path
      end

      def resource_image_variant
        :thumbnail
      end

      def taxonomy_image_path
        taxonomy = taxonomies.find { |t| t.respond_to?(:taxonomy_image) && t.taxonomy_image&.attached? }
        return unless taxonomy

        taxonomy.attached_uploader(:taxonomy_image).variant_url(taxonomy_image_variant)
      end

      def taxonomy_image_variant
        :card
      end
    end
  end
end