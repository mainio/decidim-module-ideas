# frozen_string_literal: true

module Decidim
  module Ideas
    module ApplicationHelper
      include Decidim::Comments::CommentsHelper
      include PaginateHelper
      include ::Decidim::EndorsableHelper
      include ::Decidim::FollowableHelper
      include ControlVersionHelper
      include Decidim::RichTextEditorHelper
      include Decidim::CheckBoxesTreeHelper
      include Decidim::Ideas::AreaScopesHelper

      # Public: The state of a idea in a way a human can understand.
      #
      # state - The String state of the idea.
      #
      # Returns a String.
      def humanize_idea_state(state)
        I18n.t(state, scope: "decidim.ideas.answers", default: :not_answered)
      end

      # Public: The css class applied based on the idea state.
      #
      # state - The String state of the idea.
      #
      # Returns a String.
      def idea_state_css_class(state)
        case state
        when "accepted"
          "text-success"
        when "rejected"
          "text-alert"
        when "evaluating"
          "text-warning"
        when "withdrawn"
          "text-alert"
        else
          "text-info"
        end
      end

      def idea_limit_enabled?
        idea_limit.present?
      end

      # If the rich text editor is enabled.
      def safe_content?
        rich_text_editor_in_public_views?
      end

      # If the content is safe, HTML tags are sanitized, otherwise, they are stripped.
      def render_idea_body(idea)
        body = present(idea).body(links: true, strip_tags: !safe_content?)
        body = simple_format(body, {}, sanitize: false)

        return body unless safe_content?

        decidim_sanitize(body)
      end

      # Returns :text_area or :editor based on the organization' settings.
      def text_editor_for_idea_body(form)
        options = {
          class: "js-hashtags mb-0",
          hashtaggable: true,
          value: form_presenter.body(extras: false).strip
        }

        text_editor_for(form, :body, options)
      end

      def idea_limit
        return if component_settings.idea_limit.zero?

        component_settings.idea_limit
      end

      # rubocop:disable Rails/HelperInstanceVariable
      def form_has_address?
        @form.address.present? || @form.has_address?
      end
      # rubocop:enable Rails/HelperInstanceVariable

      def authors_for(idea)
        idea.identities.map { |identity| present(identity) }
      end

      # Options to filter Ideas by activity.
      def activity_filter_values
        [
          ["all", t(".all")],
          ["my_ideas", t(".my_ideas")],
          ["my_favorites", t(".my_favorites")]
        ]
      end
    end
  end
end
