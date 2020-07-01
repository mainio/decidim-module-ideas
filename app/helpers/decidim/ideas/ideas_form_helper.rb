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

        if Decidim.geocoder[:here_api_key]
          map_html_options["data-here-api-key"] = Decidim.geocoder[:here_api_key]
        else
          # Compatibility mode for old api_id/app_code configurations
          map_html_options["data-here-app-id"] = Decidim.geocoder[:here_app_id]
          map_html_options["data-here-app-code"] = Decidim.geocoder[:here_app_code]
        end

        map_center = component_settings.default_map_center_coordinates
        map_html_options["data-center-coordinates"] = map_center if map_center

        content = capture { yield }.html_safe
        skip_link = link_to(t("skip_button", scope: "decidim.ideas.ideas.map.dynamic"), "#map_bottom", class: "skip-link")
        content_tag :div, class: "row column map-container", "aria-hidden": true do
          map = content_tag(:div, "", map_html_options)
          skip_target = link_to("", "#", id: "map_bottom")

          skip_link + map + content + skip_target
        end
      end
    end
  end
end
