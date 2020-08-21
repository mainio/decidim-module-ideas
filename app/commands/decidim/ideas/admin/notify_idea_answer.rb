# frozen_string_literal: true

module Decidim
  module Ideas
    module Admin
      # A command to notify about the change of the published state for a idea.
      class NotifyIdeaAnswer < Rectify::Command
        # Public: Initializes the command.
        #
        # idea - The idea to write the answer for.
        # initial_state - The idea state before the current process.
        def initialize(idea, initial_state)
          @idea = idea
          @initial_state = initial_state.to_s
        end

        # Executes the command. Broadcasts these events:
        #
        # - :noop when the answer is not published or the state didn't changed.
        # - :ok when everything is valid.
        #
        # Returns nothing.
        def call
          if idea.published_state? && state_changed?
            transaction do
              increment_score
              notify_followers
            end
          end

          broadcast(:ok)
        end

        private

        attr_reader :idea, :initial_state

        def state_changed?
          initial_state != idea.state.to_s
        end

        def notify_followers
          if idea.accepted?
            publish_event(
              "decidim.events.ideas.idea_accepted",
              Decidim::Ideas::AcceptedIdeaEvent
            )
          elsif idea.rejected?
            publish_event(
              "decidim.events.ideas.idea_rejected",
              Decidim::Ideas::RejectedIdeaEvent
            )
          elsif idea.evaluating?
            publish_event(
              "decidim.events.ideas.idea_evaluating",
              Decidim::Ideas::EvaluatingIdeaEvent
            )
          end
        end

        def publish_event(event, event_class)
          Decidim::EventsManager.publish(
            event: event,
            event_class: event_class,
            resource: idea,
            affected_users: idea.notifiable_identities,
            followers: idea.followers - idea.notifiable_identities
          )
        end

        def increment_score
          if idea.accepted?
            idea.coauthorships.find_each do |coauthorship|
              Decidim::Gamification.increment_score(coauthorship.user_group || coauthorship.author, :accepted_ideas)
            end
          elsif initial_state == "accepted"
            idea.coauthorships.find_each do |coauthorship|
              Decidim::Gamification.decrement_score(coauthorship.user_group || coauthorship.author, :accepted_ideas)
            end
          end
        end
      end
    end
  end
end
