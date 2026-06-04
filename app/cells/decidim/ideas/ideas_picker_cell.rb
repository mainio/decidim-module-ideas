# frozen_string_literal: true

require "cell/partial"

module Decidim
  module Ideas
    # This cell renders a ideas picker.
    class IdeasPickerCell < Decidim::ViewModel
      include Decidim::ComponentPathHelper

      delegate :current_user, :current_organization, to: :controller

      MAX_IDEAS = 1000

      def show
        if filtered?
          render :ideas
        else
          render
        end
      end

      alias component model

      def filtered?
        search_activity.present? || search_taxonomies(params).present? ||
          search_text.present?
      end

      def picker_path
        @picker_path ||= begin
          base_path, params = main_component_path(component).split("?")
          params_part = params.blank? ? "" : "?#{params}"
          "#{base_path.sub(%r{/$}, "")}/ideas/search_ideas#{params_part}"
        end
      end

      def search_text
        params[:q]
      end

      def search_activity
        params[:activity]
      end

      def search_taxonomies(params)
        params.keys
              .select { |k| k.to_s.start_with?("with_taxonomy_filter_") }
              .filter_map { |k| params[k].presence }
              .flatten
      end

      def more_ideas?
        @more_ideas ||= more_ideas_count.positive?
      end

      def more_ideas_count
        @more_ideas_count ||= ideas_count - MAX_IDEAS
      end

      def ideas_count
        @ideas_count ||= filtered_ideas.count
      end

      def decorated_ideas
        filtered_ideas.limit(MAX_IDEAS).each do |idea|
          yield Decidim::Ideas::IdeaPresenter.new(idea)
        end
      end

      def filtered_ideas
        @filtered_ideas ||= if filtered?
                              filtered_ideas_query
                            else
                              ideas
                            end
      end

      def filtered_ideas_query
        search_params = {
          search_text:,
          activity: search_activity,
          taxonomy_ids: search_taxonomies(params),
          state: "accepted"
        }

        options = {
          component: idea_components.first,
          organization: current_organization,
          current_user:
        }

        search = Decidim::Ideas::IdeaSearch.new(Decidim::Ideas::Idea.all, search_params, options)
        search.result.only_amendables.published.not_hidden.order(id: :asc)
      end

      def idea_components
        @idea_components ||= component.participatory_space.components.where(manifest_name: "ideas")
      end

      def ideas
        @ideas ||= Decidim.find_resource_manifest(:ideas).try(:resource_scope, component)
                          &.only_amendables
                          &.published
                          &.not_hidden
                          &.accepted
                          &.order(id: :asc)
      end

      def ideas_collection_name
        Decidim::Ideas::Idea.model_name.human(count: 2)
      end
    end
  end
end
