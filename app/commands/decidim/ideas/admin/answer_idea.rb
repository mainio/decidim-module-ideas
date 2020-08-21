# frozen_string_literal: true

module Decidim
  module Ideas
    module Admin
      # A command with all the business logic when an admin answers a idea.
      class AnswerIdea < Rectify::Command
        # Public: Initializes the command.
        #
        # form - A form object with the params.
        # idea - The idea to write the answer for.
        def initialize(form, idea)
          @form = form
          @idea = idea
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid.
        # - :invalid if the form wasn't valid and we couldn't proceed.
        #
        # Returns nothing.
        def call
          return broadcast(:invalid) if form.invalid?

          store_initial_idea_state

          transaction do
            answer_idea
            notify_idea_answer
          end

          broadcast(:ok)
        end

        private

        attr_reader :form, :idea, :initial_has_state_published, :initial_state

        def answer_idea
          Decidim.traceability.perform_action!(
            "answer",
            idea,
            form.current_user
          ) do
            attributes = {
              state: form.state,
              answer: form.answer,
              answered_at: Time.current
            }

            attributes[:state_published_at] = Time.current if !initial_has_state_published && form.publish_answer?

            idea.update!(attributes)
          end
        end

        def notify_idea_answer
          return if !initial_has_state_published && !form.publish_answer?

          NotifyIdeaAnswer.call(idea, initial_state)
        end

        def store_initial_idea_state
          @initial_has_state_published = idea.published_state?
          @initial_state = idea.state
        end
      end
    end
  end
end
