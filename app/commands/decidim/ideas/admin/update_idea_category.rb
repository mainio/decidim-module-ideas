# frozen_string_literal: true

module Decidim
  module Ideas
    module Admin
      #  A command with all the business logic when an admin batch updates ideas category.
      class UpdateIdeaCategory < Rectify::Command
        # Public: Initializes the command.
        #
        # category_id - the category id to update
        # idea_ids - the ideas ids to update.
        def initialize(category_id, idea_ids)
          @category = Decidim::Category.find_by id: category_id
          @idea_ids = idea_ids
          @response = { category_name: "", successful: [], errored: [] }
        end

        # Executes the command. Broadcasts these events:
        #
        # - :update_ideas_category - when everything is ok, returns @response.
        # - :invalid_category - if the category is blank.
        # - :invalid_idea_ids - if the idea_ids is blank.
        #
        # Returns @response hash:
        #
        # - :category_name - the translated_name of the category assigned
        # - :successful - Array of names of the updated ideas
        # - :errored - Array of names of the ideas not updated because they already had the category assigned
        def call
          return broadcast(:invalid_category) if @category.blank?
          return broadcast(:invalid_idea_ids) if @idea_ids.blank?

          @response[:category_name] = @category.translated_name
          Idea.where(id: @idea_ids).find_each do |idea|
            if @category == idea.category
              @response[:errored] << idea.title
            else
              transaction do
                update_idea_category idea
                notify_author idea if idea.coauthorships.any?
              end
              @response[:successful] << idea.title
            end
          end

          broadcast(:update_ideas_category, @response)
        end

        private

        def update_idea_category(idea)
          idea.update!(
            category: @category
          )
        end

        def notify_author(idea)
          Decidim::EventsManager.publish(
            event: "decidim.events.ideas.idea_update_category",
            event_class: Decidim::Ideas::Admin::UpdateIdeaCategoryEvent,
            resource: idea,
            affected_users: idea.notifiable_identities
          )
        end
      end
    end
  end
end
