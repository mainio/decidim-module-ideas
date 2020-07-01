# frozen_string_literal: true

module Decidim
  module Ideas
    module Admin
      class Permissions < Decidim::DefaultPermissions
        def permissions
          # The public part needs to be implemented yet
          return permission_action if permission_action.scope != :admin

          if create_permission_action?
            can_create_idea_from_admin?
            can_create_idea_answer?
          end

          allow! if permission_action.subject == :idea && permission_action.action == :edit && admin_edition_is_available?

          # Every user allowed by the space can update the category of the idea
          allow! if permission_action.subject == :idea_category && permission_action.action == :update

          # Every user allowed by the space can update the scope of the idea
          allow! if permission_action.subject == :idea_scope && permission_action.action == :update

          # Every user allowed by the space can import ideas from another_component
          allow! if permission_action.subject == :ideas && permission_action.action == :import

          # Every user allowed by the space can export ideas
          can_export_ideas?

          # Every user allowed by the space can merge ideas to another component
          allow! if permission_action.subject == :ideas && permission_action.action == :merge

          # Every user allowed by the space can split ideas to another component
          allow! if permission_action.subject == :ideas && permission_action.action == :split

          # Only admin users can publish many answers at once
          toggle_allow(user.admin?) if permission_action.subject == :ideas && permission_action.action == :publish_answers

          permission_action
        end

        private

        def idea
          @idea ||= context.fetch(:idea, nil)
        end

        def admin_creation_is_enabled?
          current_settings.try(:creation_enabled?)
        end

        def admin_edition_is_available?
          return unless idea

          true
        end

        def admin_idea_answering_is_enabled?
          current_settings.try(:idea_answering_enabled) &&
            component_settings.try(:idea_answering_enabled)
        end

        def create_permission_action?
          permission_action.action == :create
        end

        # Ideas can only be created from the admin when the
        # corresponding setting is enabled.
        def can_create_idea_from_admin?
          toggle_allow(admin_creation_is_enabled?) if permission_action.subject == :idea
        end

        # Ideas can only be answered from the admin when the
        # corresponding setting is enabled.
        def can_create_idea_answer?
          toggle_allow(admin_idea_answering_is_enabled?) if permission_action.subject == :idea_answer
        end

        def can_export_ideas?
          allow! if permission_action.subject == :ideas && permission_action.action == :export
        end
      end
    end
  end
end
