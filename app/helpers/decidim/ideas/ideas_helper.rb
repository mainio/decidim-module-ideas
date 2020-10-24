# frozen_string_literal: true

module Decidim
  module Ideas
    # Simple helpers to handle markup variations for ideas
    module IdeasHelper
      include Decidim::Feedback::FeedbackHelper
      include Decidim::Ideas::AreaScopesHelper

      # Serialize a collection of geocoded ideas to be used by the dynamic map component
      #
      # geocoded_ideas - A collection of geocoded ideas
      def ideas_data_for_map(geocoded_ideas)
        geocoded_ideas.map do |idea|
          idea.slice(:latitude, :longitude, :address).merge(title: present(idea).title,
                                                            body: truncate(present(idea).body, length: 100),
                                                            icon: icon("ideas", width: 40, height: 70, remove_icon_class: true),
                                                            link: idea_path(idea))
        end
      end

      def ideas_map(geocoded_ideas)
        map_options = { type: "ideas", markers: geocoded_ideas }
        map_center = component_settings.default_map_center_coordinates
        map_options[:center_coordinates] = map_center.split(",").map(&:to_f) if map_center

        dynamic_map_for(map_options) do
          yield
        end
      end

      def category_image_path(category)
        return unless category
        return unless category.respond_to?(:category_image)

        if category.category_image.blank? || category.category_image.url.blank?
          return category_image_path(category.parent) if category.parent
        end

        category.category_image.url
      end

      def idea_reason_callout_args
        {
          announcement: {
            title: idea_reason_callout_title,
            body: decidim_sanitize(translated_attribute(@idea.answer))
          },
          callout_class: idea_reason_callout_class
        }
      end

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

      def idea_reason_callout_class
        case @idea.state
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

      def idea_reason_callout_title
        i18n_key = case @idea.state
                   when "evaluating"
                     "idea_in_evaluation_reason"
                   else
                     "idea_#{@idea.state}_reason"
                   end

        t(i18n_key, scope: "decidim.ideas.ideas.show")
      end

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
        Decidim::CheckBoxesTreeHelper::TreeNode.new(
          Decidim::CheckBoxesTreeHelper::TreePoint.new("", t("decidim.ideas.application_helper.filter_state_values.all")),
          [
            Decidim::CheckBoxesTreeHelper::TreePoint.new("accepted", t("decidim.ideas.application_helper.filter_state_values.accepted")),
            Decidim::CheckBoxesTreeHelper::TreePoint.new("evaluating", t("decidim.ideas.application_helper.filter_state_values.evaluating")),
            Decidim::CheckBoxesTreeHelper::TreePoint.new("not_answered", t("decidim.ideas.application_helper.filter_state_values.not_answered")),
            Decidim::CheckBoxesTreeHelper::TreePoint.new("rejected", t("decidim.ideas.application_helper.filter_state_values.rejected"))
          ]
        )
      end

      def resource_version(resource, options = {})
        return unless resource.respond_to?(:amendable?) && resource.amendable?

        super
      end
    end
  end
end
