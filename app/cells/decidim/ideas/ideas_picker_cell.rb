# frozen_string_literal: true

require "cell/partial"

module Decidim
  module Ideas
    # This cell renders a ideas picker.
    class IdeasPickerCell < Decidim::ViewModel
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
        !search_text.nil?
      end

      def picker_path
        request.path
      end

      def search_text
        params[:q]
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
                              ideas.where("title ILIKE ?", "%#{search_text}%")
                                   .or(ideas.where("reference ILIKE ?", "%#{search_text}%"))
                                   .or(ideas.where("id::text ILIKE ?", "%#{search_text}%"))
                            else
                              ideas
                            end
      end

      def ideas
        @ideas ||= Decidim.find_resource_manifest(:ideas).try(:resource_scope, component)
                     &.published
                     &.order(id: :asc)
      end

      def ideas_collection_name
        Decidim::Ideas::Idea.model_name.human(count: 2)
      end
    end
  end
end
