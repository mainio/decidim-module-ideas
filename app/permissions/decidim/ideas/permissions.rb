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
        when :report
          true
        end
      end

      def idea
        @idea ||= context.fetch(:idea, nil) || context.fetch(:resource, nil)
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
    end
  end
end
