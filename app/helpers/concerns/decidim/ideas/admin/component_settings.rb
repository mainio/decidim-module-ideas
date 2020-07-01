# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module Ideas
    module Admin
      module ComponentSettings
        extend ActiveSupport::Concern

        include Decidim::Ideas::AreaScopesHelper

        included do
          unless respond_to?(:settings_attribute_input_orig_ideas)
            alias_method :settings_attribute_input_orig_ideas, :settings_attribute_input

            def settings_attribute_input(form, attribute, name, i18n_scope, options = {})
              if attribute.type == :idea_area_scope
                content_tag :div, class: "#{name}_container" do
                  scopes_picker_field(
                    form,
                    name,
                    root: nil,
                    options: {
                      checkboxes_on_top: true
                    }
                  )
                end
              elsif attribute.type == :idea_area_scope_coordinates
                component_id = @component.new_record? ? "new" : @component.id
                visibility_class = @component.settings.geocoding_enabled ? "" : "hide"
                value = area_scopes_coordinates(@component)
                label = t(name, scope: i18n_scope)
                coordinates_element = render(
                  partial: "decidim/ideas/admin/shared/area_scope_coordinates",
                  locals: {
                    input_name_prefix: "#{form.object_name}[#{name}]",
                    value: value,
                    parent: area_scopes_parent(@component)
                  }
                )

                label = content_tag :div, class: "card-divider" do
                  content_tag :legend, label
                end
                coordinates_element = content_tag :div, class: "card-section" do
                  coordinates_element
                end

                content_tag :div, class: "#{name}_container #{visibility_class}", data: {
                  "update-url": decidim_admin.area_coordinates_ideas_component_setting_path(component_id),
                  "setting-name": name
                } do
                  content_tag :fieldset do
                    content_tag :div, class: "card" do
                      label + coordinates_element + ideas_settings_js
                    end
                  end
                end
              else
                settings_attribute_input_orig_ideas(form, attribute, name, i18n_scope, options)
              end
            end
          end
        end

        private

        def ideas_settings_js
          return "" if @ideas_settings_js_included

          @ideas_settings_js_included = true
          javascript_include_tag("decidim/ideas/admin/component_settings")
        end
      end
    end
  end
end
