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
          # These snippets need to be added AFTER the other map scripts have
          # been added which is why they cannot be within the block. Otherwise
          # e.g. the markercluser would not be available when the ideas map is
          # loaded.
          unless snippets.any?(:ideas_map_scripts)
            snippets.add(:ideas_map_scripts, javascript_pack_tag("decidim_ideas_map"))
            snippets.add(:foot, snippets.for(:ideas_map_scripts))
          end

          if block_given?
            yield
          else
            ""
          end
        end
      end

      def file_is_present?(form, attribute)
        file_form = form.object.send attribute
        return false unless file_form

        file = file_form.file
        return false unless file && file.respond_to?(:attached?) && file.attached?

        file.present?
      end
    end
  end
end
