# frozen_string_literal: true

require "cell/partial"

module Decidim
  module Ideas
    # This cell renders a ideas picker.
    class IdeasPickerInlineCell < Decidim::Ideas::IdeasPickerCell
      include ActionView::Helpers::FormOptionsHelper
      include Cell::ViewModel::Partial
      include Decidim::LayoutHelper # For the icon helper
      include Decidim::FilterResource
      include Decidim::Ideas::AreaScopesHelper

      alias current_component component

      delegate :snippets, to: :controller

      def show
        unless snippets.any?(:idea_picker_inline)
          snippets.add(
            :idea_picker_inline,
            javascript_pack_tag("decidim_ideas_idea_picker_inline")
          )
          snippets.add(
            :idea_picker_inline,
            stylesheet_pack_tag("decidim_ideas_idea_picker_inline")
          )

          # This will display the snippets in the <head> part of the page.
          snippets.add(:head, snippets.for(:idea_picker_inline))
        end

        if filtered?
          render :ideas
        else
          render
        end
      end

      def more_ideas_count
        @more_ideas_count ||= ideas_count - max_ideas
      end

      def decorated_ideas
        filtered_ideas.limit(max_ideas).each do |idea|
          yield Decidim::Ideas::IdeaPresenter.new(idea)
        end
      end

      private

      def form
        context[:form]
      end

      def presenter_for(idea)
        @presenters ||= {}

        @presenters[idea.id] ||= Decidim::Ideas::IdeaPresenter.new(idea)
      end

      def picker_id
        @picker_id ||= "idea_picker_#{SecureRandom.uuid}"
      end

      def idea_link_for(idea)
        routes_proxy.idea_path(idea)
      end

      def max_ideas
        20
      end

      def selected_ideas
        return [] unless form

        form.object.ideas
      end

      # Options to filter Ideas by activity.
      def activity_filter_values
        [
          ["all", t(".filters.all")],
          ["my_ideas", t(".filters.my_ideas")],
          ["my_favorites", t(".filters.my_favorites")]
        ]
      end

      def filter_ideas_categories_values
        organization = component.participatory_space.organization

        sorted_main_categories = component.participatory_space.categories.first_class.includes(:subcategories).sort_by do |category|
          [category.weight, translated_attribute(category.name, organization)]
        end

        categories_values = []
        sorted_main_categories.each do |category|
          category_name = translated_attribute(category.name, organization)
          categories_values << [category_name, category.id]
        end
        categories_values
      end

      def current_locale
        I18n.locale.to_s
      end

      def routes_proxy
        @routes_proxy ||= ::Decidim::EngineRouter.main_proxy(current_component)
      end
    end
  end
end
