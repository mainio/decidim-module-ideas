# frozen_string_literal: true

module Decidim
  module Ideas
    # A command with all the business logic when a user publishes a draft idea.
    class PublishIdea < Rectify::Command
      # Public: Initializes the command.
      #
      # idea     - The idea to publish.
      # current_user - The current user.
      def initialize(idea, current_user)
        @idea = idea
        @current_user = current_user
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when everything is valid and the idea is published.
      # - :invalid if the idea's author is not the current user.
      #
      # Returns nothing.
      def call
        return broadcast(:invalid) unless @idea.authored_by?(@current_user)

        transaction do
          publish_idea
          increment_scores
          send_notification
          send_notification_to_participatory_space
        end

        broadcast(:ok, @idea)
      end

      private

      # This will be the PaperTrail version that is
      # shown in the version control feature (1 of 1)
      #
      # For an attribute to appear in the new version it has to be reset
      # and reassigned, as PaperTrail only keeps track of object CHANGES.
      def publish_idea
        title = reset(:title)
        body = reset(:body)
        address = reset(:address)
        latitude = reset(:latitude)
        longitude = reset(:longitude)
        area_scope_id = reset(:area_scope_id)
        category = @idea.category

        if @idea.categorization
          PaperTrail.request(enabled: false) do
            @idea.categorization.destroy!
          end
        end

        Decidim.traceability.perform_action!(
          "publish",
          @idea,
          @current_user,
          visibility: "public-only"
        ) do
          @idea.update(
            title: title,
            body: body,
            address: address,
            latitude: latitude,
            longitude: longitude,
            area_scope_id: area_scope_id,
            category: category,
            published_at: Time.current
          )
        end
      end

      # Reset the attribute to an empty string and return the old value
      def reset(attribute)
        attribute_value = @idea[attribute]
        PaperTrail.request(enabled: false) do
          @idea.update_attribute attribute, "" # rubocop:disable Rails/SkipsModelValidations
        end
        attribute_value
      end

      def send_notification
        return if @idea.coauthorships.empty?

        Decidim::EventsManager.publish(
          event: "decidim.events.ideas.idea_published",
          event_class: Decidim::Ideas::PublishIdeaEvent,
          resource: @idea,
          followers: coauthors_followers
        )
      end

      def send_notification_to_participatory_space
        Decidim::EventsManager.publish(
          event: "decidim.events.ideas.idea_published",
          event_class: Decidim::Ideas::PublishIdeaEvent,
          resource: @idea,
          followers: @idea.participatory_space.followers - coauthors_followers,
          extra: {
            participatory_space: true
          }
        )
      end

      def coauthors_followers
        @coauthors_followers ||= @idea.authors.flat_map(&:followers)
      end

      def increment_scores
        @idea.coauthorships.find_each do |coauthorship|
          if coauthorship.user_group
            Decidim::Gamification.increment_score(coauthorship.user_group, :ideas)
          else
            Decidim::Gamification.increment_score(coauthorship.author, :ideas)
          end
        end
      end
    end
  end
end
