# frozen_string_literal: true

module Decidim
  module Ideas
    class IdeaWidgetsController < Decidim::WidgetsController
      helper Ideas::ApplicationHelper

      private

      def model
        @model ||= Idea.where(component: params[:component_id]).find(params[:idea_id])
      end

      def iframe_url
        @iframe_url ||= idea_idea_widget_url(model)
      end
    end
  end
end
