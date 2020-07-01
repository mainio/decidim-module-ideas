# frozen_string_literal: true

module Decidim
  module Ideas
    class ApplicationController < Decidim::Components::BaseController
      default_form_builder Decidim::Ideas::FormBuilder

      helper Decidim::Ideas::FormHelper
      helper Decidim::Messaging::ConversationHelper
      helper_method :idea_limit_reached?

      def idea_limit
        return nil if component_settings.idea_limit.zero?

        component_settings.idea_limit
      end

      def idea_limit_reached?
        return false unless idea_limit

        ideas.where(author: current_user).count >= idea_limit
      end

      def ideas
        Idea.where(component: current_component)
      end
    end
  end
end
