# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module Ideas
    module Admin
      module ComponentSettings
        extend ActiveSupport::Concern

        included do
          unless method_defined?(:settings_attribute_input_orig_ideas)
            alias_method :settings_attribute_input_orig_ideas, :settings_attribute_input

            # rubocop:disable Rails/HelperInstanceVariable
            def settings_attribute_input(form, attribute, name, i18n_scope, options = {})
              case attribute.type
              when :idea_area_scope
                content_tag :div, class: "#{name}_container" do
                  scopes_select_field(
                    form,
                    name,
                    root: nil,
                    options: {
                      checkboxes_on_top: true
                    }
                  )
                end
              when :idea_area_scope_coordinates
                component_id = @component.new_record? ? "new" : @component.id
                visibility_class = @component.settings.geocoding_enabled ? "" : "hide"
                value = area_scopes_coordinates(@component)
                label = t(name, scope: i18n_scope)
                coordinates_element = render(
                  partial: "decidim/ideas/admin/shared/area_scope_coordinates",
                  locals: {
                    input_name_prefix: "#{form.object_name}[#{name}]",
                    value:,
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
                      settings_js =
                        if @ideas_settings_js_included
                          ""
                        else
                          @ideas_settings_js_included = true
                          append_javascript_pack_tag("decidim_ideas_admin_component_settings")
                        end

                      label + coordinates_element + settings_js
                    end
                  end
                end
              else
                settings_attribute_input_orig_ideas(form, attribute, name, i18n_scope, options)
              end
            end
            # rubocop:enable Rails/HelperInstanceVariable
          end
        end
      end
    end
  end
end
