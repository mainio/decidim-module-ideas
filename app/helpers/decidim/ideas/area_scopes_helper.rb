# frozen_string_literal: true

module Decidim
  module Ideas
    # A Helper to render scopes, including a global scope, for forms.
    module AreaScopesHelper
      include DecidimFormHelper
      include TranslatableAttributes

      # Checks if the resource should show its scope or not.
      # resource - the resource to analize
      #
      # Returns boolean.
      def has_visible_area_scope?(resource)
        parent_scope = area_scopes_parent(resource.component)
        return false unless parent_scope

        resource.area_scope.present? && parent_scope != resource.area_scope
      end

      def area_scopes_parent(component = current_component)
        @area_scopes_parent ||= begin
          parent_id = component.settings.area_scope_parent_id
          return unless parent_id

          Decidim::Scope.find_by(id: parent_id)
        end
      end

      def area_scopes_coordinates(component = current_component)
        area_scopes_default_coordinates(component).merge(
          component.settings.area_scope_coordinates
        )
      end

      def area_scopes_default_coordinates(component = current_component, parent = nil)
        parent ||= area_scopes_parent(component)
        return {} unless parent

        final = {}
        scope_children(parent).each do |scope|
          final[scope.id.to_s] = ""
          final.merge!(area_scopes_default_coordinates(component, scope)) if scope.children
        end
        final
      end

      # Retrieves the translated name and type for an scope.
      # scope - a Decidim::Scope
      # global_name - text to use when scope is nil
      #
      # Returns a string
      def area_scope_name_for_picker(scope, global_name)
        return global_name unless scope

        name = translated_attribute(scope.name)
        name << " (#{translated_attribute(scope.scope_type.name)})" if scope.scope_type
        name
      end

      # Renders a scopes select field in a form.
      # form - FormBuilder object
      # name - attribute name
      # options - Options for the select field
      # html_options - HTML options for the select field
      #
      # Returns nothing.
      def area_scopes_picker_field(form, name, root: false, options: {}, html_options: {})
        root = area_scopes_parent if root == false

        form.select(name, area_scopes_options(root), options, html_options)
      end

      # Renders a scopes select field in a form, not linked to a specific model.
      # name - name for the input
      # value - value for the input
      # options - Options for the select field
      # html_options - HTML options for the select field
      #
      # Returns nothing.
      def area_scopes_picker_tag(name, value, options: {}, html_options: {})
        root = area_scopes_parent
        field = options[:field] || name

        select_tag(
          name,
          options_for_select(
            area_scopes_options(root),
            value
          ),
          options,
          html_options
        )
      end

      # Renders a scopes select field in a filter form.
      # form - FilterFormBuilder object
      # name - attribute name
      # options - Options for the select field
      # html_options - HTML options for the select field
      #
      # Returns nothing.
      def area_scopes_picker_filter(form, name, options: {}, html_options: {})
        area_scopes_picker_field(form, name, options, html_options)
      end

      private

      def scope_children(scope)
        scope.children.order("name->>'#{current_locale}'")
      end

      def area_scopes_options(parent, name_prefix = "")
        options = []
        scope_children(parent).each do |scope|
          options.push(["#{name_prefix}#{translated_attribute(scope.name)}", scope.id])

          sub_prefix = "#{name_prefix}#{translated_attribute(scope.name)} / "
          options.push(*area_scopes_options(scope, sub_prefix))
        end
        options
      end
    end
  end
end
