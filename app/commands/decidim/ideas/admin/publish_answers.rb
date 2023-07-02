# frozen_string_literal: true

module Decidim
  module Ideas
    module Admin
      # A command with all the business logic to publish many answers at once.
      class PublishAnswers < Decidim::Command
        # Public: Initializes the command.
        #
        # component - The component that contains the answers.
        # user - the Decidim::User that is publishing the answers.
        # idea_ids - the identifiers of the ideas with the answers to be published.
        def initialize(component, user, idea_ids)
          @component = component
          @user = user
          @idea_ids = idea_ids
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid.
        # - :invalid if there are not ideas to publish.
        #
        # Returns nothing.
        def call
          return broadcast(:invalid) unless ideas.any?

          ideas.each do |idea|
            transaction do
              mark_idea_as_answered(idea)
              notify_idea_answer(idea)
            end
          end

          broadcast(:ok)
        end

        private

        attr_reader :component, :user, :idea_ids

        def ideas
          @ideas ||= Decidim::Ideas::Idea.published
                                         .answered
                                         .state_not_published
                                         .where(component: component)
                                         .where(id: idea_ids)
        end

        def mark_idea_as_answered(idea)
          Decidim.traceability.perform_action!(
            "publish_answer",
            idea,
            user
          ) do
            idea.update!(state_published_at: Time.current)
          end
        end

        def notify_idea_answer(idea)
          NotifyIdeaAnswer.call(idea, nil)
        end
      end
    end
  end
end
