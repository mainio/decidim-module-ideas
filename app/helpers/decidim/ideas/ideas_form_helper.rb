# frozen_string_literal: true

module Decidim
  module Ideas
    module IdeasFormHelper
      include Decidim::MapHelper

      def file_field(object_name, method, options = {})
        options[:disabled] = true unless user_signed_in?

        super(object_name, method, options)
      end

      def idea_form_map(map_html_options = {})
        map_options = { type: "idea-form" }
        map_center = component_settings.default_map_center_coordinates
        map_options[:center_coordinates] = map_center.split(",").map(&:to_f) if map_center

        dynamic_map_for(map_options, map_html_options) do
          javascript_include_tag "decidim/ideas/map"
        end
      end

      def file_is_present?(form, attribute)
        file_form = form.object.send attribute
        return unless file_form

        file = file_form.file
        return unless file && file.respond_to?(:url)

        file.present?
      end
    end
  end
end
