# frozen_string_literal: true

module Decidim
  module Ideas
    # Simple helpers to handle markup variations for ideas
    module IdeasHelper
      include Decidim::Feedback::FeedbackHelper
      include Decidim::Ideas::AreaScopesHelper

      # Serialize a collection of geocoded ideas to be used by the dynamic map
      # component. The serialized list is made for the flat list fetched with
      # `Idea.geocoded_data_for` in order to make the processing faster.
      #
      # geocoded_ideas_data - A flat array of the idea data received from `Idea.geocoded_data_for`
      def ideas_data_for_map(geocoded_ideas_data)
        geocoded_ideas_data.map do |data|
          {
            id: data[0],
            title: data[1],
            body: truncate(data[2], length: 100),
            address: data[3],
            latitude: data[4],
            longitude: data[5],
            link: idea_path(data[0])
          }
        end
      end

      def ideas_map(geocoded_ideas, **options)
        map_options = { type: "ideas", markers: geocoded_ideas }
        map_center = component_settings.default_map_center_coordinates
        map_options[:center_coordinates] = map_center.split(",").map(&:to_f) if map_center

        dynamic_map_for(map_options.merge(options)) do
          # These snippets need to be added AFTER the other map scripts have
          # been added which is why they cannot be within the block. Otherwise
          # e.g. the markercluser would not be available when the idas map is
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

      def display_answer_filter?
        @display_answer_filter ||= component_settings.idea_answering_enabled && current_settings.idea_answering_enabled
      end

      def display_scope_filter?
        @display_scope_filter ||= component_settings.area_scope_parent_id && Decidim::Scope.exists?(component_settings.area_scope_parent_id)
      end

      def display_category_filter?
        @display_category_filter ||= current_component.categories.any?
      end

      def category_image_path(category)
        return unless category
        return unless category.respond_to?(:category_image)

        return category_image_path(category.parent) if (category.category_image.blank? || !category.category_image.attached?) && category.parent

        category.attached_uploader(:category_image).url
      end

      def idea_reason_callout_args
        {
          announcement: {
            title: idea_reason_callout_title,
            body: decidim_sanitize(translated_attribute(@idea.answer)) # rubocop:disable Rails/HelperInstanceVariable
          },
          callout_class: idea_reason_callout_class
        }
      end

      # rubocop:disable Rails/HelperInstanceVariable
      def idea_map_link(resource, options = {})
        @map_utility_static ||= Decidim::Map.static(
          organization: current_organization
        )
        return "#" unless @map_utility_static

        @map_utility_static.link(
          latitude: resource.latitude,
          longitude: resource.longitude,
          options: options
        )
      end
      # rubocop:enable Rails/HelperInstanceVariable

      def idea_reason_callout_class
        case @idea.state # rubocop:disable Rails/HelperInstanceVariable
        when "accepted"
          "success"
        when "evaluating"
          "warning"
        when "rejected"
          "alert"
        else
          ""
        end
      end

      # rubocop:disable Rails/HelperInstanceVariable
      def idea_reason_callout_title
        i18n_key = case @idea.state
                   when "evaluating"
                     "idea_in_evaluation_reason"
                   else
                     "idea_#{@idea.state}_reason"
                   end

        t(i18n_key, scope: "decidim.ideas.ideas.show")
      end
      # rubocop:enable Rails/HelperInstanceVariable

      def filter_ideas_categories_values
        organization = current_participatory_space.organization

        sorted_main_categories = current_participatory_space.categories.first_class.includes(:subcategories).sort_by do |category|
          [category.weight, translated_attribute(category.name, organization)]
        end

        categories_values = []
        sorted_main_categories.each do |category|
          category_name = translated_attribute(category.name, organization)
          categories_values << [category_name, category.id]

          # sorted_descendant_categories = category.descendants.includes(:subcategories).sort_by do |subcategory|
          #   [subcategory.weight, translated_attribute(subcategory.name, organization)]
          # end

          # name_prefix = "#{category_name} / "
          # sorted_descendant_categories.each do |subcategory|
          #   categories_values << ["#{name_prefix}#{translated_attribute(subcategory.name, organization)}", subcategory.id]
          # end
        end
        categories_values
      end

      def filter_ideas_state_values
        [
          [t("decidim.ideas.application_helper.filter_state_values.accepted"), "accepted"],
          [t("decidim.ideas.application_helper.filter_state_values.rejected"), "rejected"],
          [t("decidim.ideas.application_helper.filter_state_values.not_answered"), "not_answered"]
        ]
      end

      def resource_version(resource, options = {})
        return unless resource.respond_to?(:amendable?) && resource.amendable?

        super
      end
    end
  end
end
