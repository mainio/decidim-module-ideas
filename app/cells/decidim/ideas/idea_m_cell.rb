# frozen_string_literal: true

require "cell/partial"

module Decidim
  module Ideas
    # This cell renders a idea with its M-size card.
    class IdeaMCell < Decidim::CardMCell
      include IdeaCellsHelper

      property :area_scope

      def badge
        render if has_badge?
      end

      private

      def preview?
        options[:preview]
      end

      def render_column?
        !context[:no_column].presence
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
        return false if model.emendation?

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
        return [:creation_date, :comments_count] if !has_link_to_resource? || !can_be_followed?

        [:creation_date, :follow, :comments_count]
      end

      def creation_date_status
        l(model.published_at.to_date, format: :decidim_short)
      end

      def progress_bar_progress
        model.idea_votes_count || 0
      end

      def progress_bar_total
        model.maximum_votes || 0
      end

      def progress_bar_subtitle_text
        if progress_bar_progress >= progress_bar_total
          t("decidim.ideas.ideas.votes_count.most_popular_idea")
        else
          t("decidim.ideas.ideas.votes_count.need_more_votes")
        end
      end

      def can_be_followed?
        !model.withdrawn?
      end

      def has_image?
        model.image.present? && model.image.file.content_type.start_with?("image") && model.component.settings.image_allowed?
      end

      def resource_image_path
        model.image.thumbnail_url if has_image?
      end
    end
  end
end
