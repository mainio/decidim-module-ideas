# frozen_string_literal: true

module Decidim
  module Ideas
    class Permissions < Decidim::DefaultPermissions
      def permissions
        return permission_action unless user

        # Delegate the admin permission checks to the admin permissions class
        return Decidim::Ideas::Admin::Permissions.new(user, permission_action, context).permissions if permission_action.scope == :admin
        return permission_action if permission_action.scope != :public

        if permission_action.subject == :idea
          apply_idea_permissions(permission_action)
        else
          permission_action
        end

        permission_action
      end

      private

      def apply_idea_permissions(permission_action)
        case permission_action.action
        when :create
          can_create_idea?
        when :edit
          can_edit_idea?
        when :withdraw
          can_withdraw_idea?
        when :amend
          can_create_amendment?
        when :vote
          can_vote_idea?
        when :unvote
          can_unvote_idea?
        when :report
          true
        end
      end

      def idea
        @idea ||= context.fetch(:idea, nil) || context.fetch(:resource, nil)
      end

      def voting_enabled?
        return unless current_settings

        current_settings.votes_enabled? && !current_settings.votes_blocked?
      end

      def vote_limit_enabled?
        return unless component_settings

        component_settings.vote_limit.present? && component_settings.vote_limit.positive?
      end

      def remaining_votes
        return 1 unless vote_limit_enabled?

        ideas = Idea.where(component: component)
        votes_count = IdeaVote.where(author: user, idea: ideas).size
        component_settings.vote_limit - votes_count
      end

      def can_create_idea?
        toggle_allow(authorized?(:create) && current_settings&.creation_enabled?)
      end

      def can_edit_idea?
        toggle_allow(idea && idea.editable_by?(user))
      end

      def can_withdraw_idea?
        toggle_allow(idea && idea.authored_by?(user))
      end

      def can_create_amendment?
        is_allowed = idea &&
                     authorized?(:amend, resource: idea) &&
                     current_settings&.amendments_enabled?

        toggle_allow(is_allowed)
      end

      def can_vote_idea?
        is_allowed = idea &&
                     authorized?(:vote, resource: idea) &&
                     voting_enabled? &&
                     remaining_votes.positive?

        toggle_allow(is_allowed)
      end

      def can_unvote_idea?
        is_allowed = idea &&
                     authorized?(:vote, resource: idea) &&
                     voting_enabled?

        toggle_allow(is_allowed)
      end
    end
  end
end
