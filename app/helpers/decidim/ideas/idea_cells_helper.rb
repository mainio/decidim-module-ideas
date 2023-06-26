# frozen_string_literal: true

module Decidim
  module Ideas
    # Custom helpers, scoped to the ideas engine.
    #
    module IdeaCellsHelper
      include Decidim::Ideas::ApplicationHelper
      include Decidim::Ideas::Engine.routes.url_helpers
      include Decidim::LayoutHelper
      include Decidim::ApplicationHelper
      include Decidim::TranslationsHelper
      include Decidim::ResourceReferenceHelper
      include Decidim::TranslatableAttributes
      include Decidim::CardHelper

      delegate :title, :state, :published_state?, :withdrawn?, :amendable?, :emendation?, to: :model

      def has_actions?
        return context[:has_actions] if context[:has_actions].present?

        ideas_controller? && index_action? && !model.draft?
      end

      def has_footer?
        return context[:has_footer] if context[:has_footer].present?

        ideas_controller? && index_action? && !model.draft?
      end

      def ideas_controller?
        context[:controller].class.to_s == "Decidim::Ideas::IdeasController"
      end

      def index_action?
        context[:controller].action_name == "index"
      end

      def current_settings
        model.component.current_settings
      end

      def component_settings
        model.component.settings
      end

      def current_component
        model.component
      end

      # rubocop:disable Rails/HelperInstanceVariable
      def from_context
        @options[:from]
      end
      # rubocop:enable Rails/HelperInstanceVariable

      def badge_name
        humanize_idea_state state
      end

      def state_classes
        case state
        when "accepted"
          ["success"]
        when "rejected"
          ["alert"]
        when "evaluating"
          ["warning"]
        when "withdrawn"
          ["alert"]
        else
          [""]
        end
      end
    end
  end
end
