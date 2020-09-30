# frozen_string_literal: true

module Decidim
  module Ideas
    module ApplicationHelper
      include Decidim::Comments::CommentsHelper
      include PaginateHelper
      include IdeaVotesHelper
      include ::Decidim::EndorsableHelper
      include ::Decidim::FollowableHelper
      include ControlVersionHelper
      include Decidim::RichTextEditorHelper
      include Decidim::CheckBoxesTreeHelper
      include Decidim::Ideas::AreaScopesHelper

      delegate :minimum_votes_per_user, to: :component_settings

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

      def minimum_votes_per_user_enabled?
        minimum_votes_per_user.positive?
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

      def votes_given
        @votes_given ||= IdeaVote.where(
          idea: Idea.where(component: current_component),
          author: current_user
        ).count
      end

      def votes_count_for(model, from_ideas_list)
        render partial: "decidim/ideas/ideas/idea_votes_count.html", locals: { idea: model, from_ideas_list: from_ideas_list }
      end

      def vote_button_for(model, from_ideas_list)
        render partial: "decidim/ideas/ideas/idea_vote_button.html", locals: { idea: model, from_idea_list: from_ideas_list }
      end

      def form_has_address?
        @form.address.present? || @form.has_address?
      end

      def authors_for(idea)
        idea.identities.map { |identity| present(identity) }
      end

      def show_voting_rules?
        return false unless votes_enabled?

        return true if vote_limit_enabled?
        return true if threshold_per_idea_enabled?
        return true if idea_limit_enabled?
        return true if can_accumulate_supports_beyond_threshold?
        return true if minimum_votes_per_user_enabled?
      end

      def filter_type_values
        [
          ["all", t("decidim.ideas.application_helper.filter_type_values.all")],
          ["ideas", t("decidim.ideas.application_helper.filter_type_values.ideas")],
          ["amendments", t("decidim.ideas.application_helper.filter_type_values.amendments")]
        ]
      end

      # Options to filter Ideas by activity.
      def activity_filter_values
        base = [
          ["all", t(".all")],
          ["my_ideas", t(".my_ideas")]
        ]
        base += [["voted", t(".voted")]] if current_settings.votes_enabled?
        base
      end
    end
  end
end
