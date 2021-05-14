# frozen_string_literal: true

module Decidim
  module Ideas
    module Admin
      #  A command with all the business logic when an admin batch updates ideas scope.
      class UpdateIdeaAreaScope < Rectify::Command
        include TranslatableAttributes
        # Public: Initializes the command.
        #
        # scope_id - the scope id to update
        # idea_ids - the ideas ids to update.
        def initialize(scope_id, idea_ids)
          @scope = Decidim::Scope.find_by id: scope_id
          @idea_ids = idea_ids
          @response = { scope_name: "", successful: [], errored: [] }
        end

        # Executes the command. Broadcasts these events:
        #
        # - :update_ideas_scope - when everything is ok, returns @response.
        # - :invalid_scope - if the scope is blank.
        # - :invalid_ideas_ids - if the idea_ids is blank.
        #
        # Returns @response hash:
        #
        # - :scope_name - the translated_name of the scope assigned
        # - :successful - Array of names of the updated ideas
        # - :errored - Array of names of the ideas not updated because they already had the scope assigned
        def call
          return broadcast(:invalid_scope) if @scope.blank?
          return broadcast(:invalid_idea_ids) if @idea_ids.blank?

          update_ideas_scope

          broadcast(:update_ideas_scope, @response)
        end

        private

        attr_reader :scope, :idea_ids

        def update_ideas_scope
          @response[:scope_name] = translated_attribute(scope.name, scope.organization)
          Idea.where(id: idea_ids).find_each do |idea|
            if scope == idea.area_scope
              @response[:errored] << idea.title
            else
              transaction do
                update_idea_area_scope idea
                notify_author idea if idea.coauthorships.any?
              end
              @response[:successful] << idea.title
            end
          end
        end

        def update_idea_area_scope(idea)
          idea.update!(
            area_scope: scope
          )
        end

        def notify_author(idea)
          Decidim::EventsManager.publish(
            event: "decidim.events.ideas.idea_update_area_scope",
            event_class: Decidim::Ideas::Admin::UpdateIdeaAreaScopeEvent,
            resource: idea,
            affected_users: idea.notifiable_identities
          )
        end
      end
    end
  end
end
