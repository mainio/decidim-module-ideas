# frozen_string_literal: true

require "cell/partial"

module Decidim
  module Ideas
    # This cell renders the tags for a idea.
    class IdeaTagsCell < Decidim::ViewModel
      include IdeaCellsHelper

      property :category
      property :previous_category
      property :area_scope
      property :previous_area_scope

      def show
        render if has_category_or_area_scopes?
      end

      private

      def show_previous_category?
        options[:show_previous_category].to_s != "false"
      end

      def show_previous_area_scope?
        options[:show_previous_area_scope].to_s != "false"
      end

      def has_category_or_area_scopes?
        category.present? || has_visible_area_scopes?(model)
      end
    end
  end
end
