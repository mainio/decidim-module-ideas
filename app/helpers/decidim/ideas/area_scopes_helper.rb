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
        filter = area_scopes_parent(resource.component)
        return false unless filter
        return false if resource.taxonomies.empty?

        filter_taxonomy_ids = filter.taxonomies.values.flat_map { |node| collect_taxonomy_ids(node) }
        resource.taxonomies.map(&:id).intersect?(filter_taxonomy_ids)
      end

      def area_scopes_parent(component = current_component)
        filter_id = component.settings.area_taxonomy_filter_id
        return unless filter_id

        @area_scopes_parent ||= Decidim::TaxonomyFilter.find_by(id: filter_id)
      end

      def area_scopes_coordinates(component = current_component)
        area_scopes_default_coordinates(component).merge(
          component.settings.area_scope_coordinates.transform_keys(&:to_s)
        )
      end

      def area_scopes_default_coordinates(component = current_component, taxonomies = nil)
        taxonomies ||= area_scopes_parent(component)&.taxonomies
        return {} unless taxonomies

        final = {}
        taxonomies.each do |_id, node|
          final[node[:taxonomy].id.to_s] = ""
          final.merge!(area_scopes_default_coordinates(component, node[:children])) if node[:children].any?
        end
        final
      end

      # Renders a scopes select field in a form.
      # form - FormBuilder object
      # name - attribute name
      # options - Options for the select field
      # html_options - HTML options for the select field
      #
      # Returns nothing.
      def area_scopes_picker_field(form, name, root: false, options: {}, html_options: {})
        filter = root == false ? area_scopes_parent : root
        return unless filter

        form.select(name, area_scopes_options(filter.taxonomies), options, html_options)
      end

      # Renders a scopes select field in a form, not linked to a specific model.
      # name - name for the input
      # value - value for the input
      # options - Options for the select field
      # html_options - HTML options for the select field
      #
      # Returns nothing.
      def area_scopes_picker_tag(name, value, options: {}, html_options: {})
        filter = area_scopes_parent
        return unless filter

        select_tag(
          name,
          options_for_select(
            area_scopes_options(filter.taxonomies),
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
        area_scopes_picker_field(form, name, options: options, html_options: html_options)
      end

      private

      def scope_children(scope)
        scope.children.order(Arel.sql("code, name->>'#{current_locale}'"))
      end

      def area_scopes_options(taxonomies, name_prefix = "")
        options = []
        taxonomies.each do |_id, node|
          taxonomy = node[:taxonomy]
          options.push(["#{name_prefix}#{translated_attribute(taxonomy.name)}", taxonomy.id])

          sub_prefix = "#{name_prefix}#{translated_attribute(taxonomy.name)} / "
          options.push(*area_scopes_options(node[:children], sub_prefix)) if node[:children].any?
        end
        options
      end

      def collect_taxonomy_ids(node)
        ids = [node[:taxonomy].id]
        ids + node[:children].values.flat_map { |child_node| collect_taxonomy_ids(child_node) }
      end
    end
  end
end
