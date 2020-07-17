# frozen_string_literal: true

module Decidim
  module Ideas
    module IdeasFormHelper
      def file_field(object_name, method, options = {})
        options[:disabled] = true unless user_signed_in?

        super(object_name, method, options)
      end

      def idea_form_map(map_html_options = {})
        return if Decidim.geocoder.blank?

        map_html_options = { id: "map", class: "google-map" }.merge(map_html_options)

        map_center = component_settings.default_map_center_coordinates
        map_html_options["data-center-coordinates"] = map_center if map_center

        content = capture { yield }.html_safe
        skip_link = link_to(t("skip_button", scope: "decidim.ideas.ideas.map.dynamic"), "#map_bottom", class: "skip-link")
        map_configuration = javascript_tag do
          %{
            $(document).ready(function() {
              #{map_utility.js_map_configure(map_html_options[:id])}
            });
          }.html_safe
        end
        map_container = content_tag(
          :div,
          class: "row column map-container",
          "aria-hidden": true
        ) do
          map = content_tag(:div, "", map_html_options)
          skip_target = link_to("", "#", id: "map_bottom")

          skip_link + map + map_configuration + content + skip_target
        end

        map_container + map_configuration
      end

      private

      def map_utility
        @map_utility ||= Decidim::Ideas.map_utility.new(
          organization: current_organization
        )
      end
    end
  end
end
