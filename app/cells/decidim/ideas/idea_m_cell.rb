# frozen_string_literal: true

require "cell/partial"

module Decidim
  module Ideas
    # This cell renders a idea with its M-size card.
    class IdeaMCell < Decidim::CardMCell
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

      def filter_link_params(params = nil)
        super(params).merge(resource_utm_params)
      end

      private

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

      def body
        decidim_sanitize(present(model).body)
      end

      def category
        translated_attribute(model.category.name) if has_category?
      end

      def full_category
        return unless has_category?

        parts = []
        parts << translated_attribute(model.category.parent.name) if model.category.parent
        parts << category

        parts.join(" - ")
      end

      def category_class
        "card__category--#{model.category.id}" if has_category?
      end

      def has_state?
        model.published?
      end

      def has_category?
        model.category.present?
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

        state_classes.concat(["label", "idea-status"]).join(" ")
      end

      def statuses
        return [] if preview?
        return [:comments_count] if model.draft?

        [:creation_date, :favoriting_count, :comments_count]
      end

      def creation_date_status
        l(model.published_at.to_date, format: :decidim_short)
      end

      def favoriting_count_status
        cell("decidim/favorites/favoriting_count", model)
      end

      def category_icon
        cat = icon_category
        return unless cat

        content_tag(:span, class: "card__category__icon", "aria-hidden": true) do
          image_tag(cat.attached_uploader(:category_icon).path, alt: full_category)
        end
      end

      def category_style
        cat = color_category
        return unless cat

        "background-color:#{cat.color};"
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
        return model.image.thumbnail_url if has_image?

        path = category_image_path(model.category)
        return path if path

        category_image_path(model.category.parent) if model.category&.parent.present?
      end

      def category_image_path(cat)
        return unless has_category?
        return unless cat.respond_to?(:category_image)
        return unless cat.category_image

        cat.attached_uploader(:category_image).path(variant: :card)
      end

      def icon_category(cat = nil)
        return unless has_category?

        cat ||= model.category
        return unless cat.respond_to?(:category_icon)
        return cat if cat.category_icon && cat.category_icon.attached?
        return unless cat.parent

        icon_category(cat.parent)
      end

      def color_category(cat = nil)
        return unless has_category?

        cat ||= model.category
        return unless cat.respond_to?(:color)
        return cat if cat.color
        return unless cat.parent

        color_category(cat.parent)
      end
    end
  end
end
