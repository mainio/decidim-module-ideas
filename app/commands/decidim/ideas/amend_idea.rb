# frozen_string_literal: true

module Decidim
  module Ideas
    # A command with all the business logic when amends an idea.
    class AmendIdea < Rectify::Command
      include ::Decidim::Ideas::AttachmentMethods
      include ::Decidim::Ideas::ImageMethods
      include HashtagsMethods

      # Public: Initializes the command.
      #
      # form         - A form object with the params.
      # current_user - The current user.
      # idea - the idea to amend.
      def initialize(form, current_user, idea)
        @form = form
        @current_user = current_user
        @amendable = idea
        @user_group = Decidim::UserGroup.find_by(id: form.user_group_id)
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when everything is valid, together with the amend.
      # - :invalid if the form wasn't valid and we couldn't proceed.
      #
      # Returns nothing.
      def call
        return broadcast(:invalid) if form.invalid?

        if process_image?
          build_image
          return broadcast(:invalid) if image_invalid?
        end
        if process_attachments?
          build_attachment
          return broadcast(:invalid) if attachment_invalid?
        end

        transaction do
          create_emendation!
          create_amendment!
          publish_emendation
          update_amendable!
          notify_emendation_state_change!
          if amendment.state == "accepted"
            notify_amendable_and_emendation_authors_and_followers
          else
            # If the amendment was not accepted, it requires action from its
            # authors. This notifies them accordingly.
            notify_amendable_authors_and_followers
          end
        end

        if amendment.state == "accepted"
          broadcast(:ok, amendable)
        else
          broadcast(:ok, emendation)
        end
      end

      private

      attr_reader :form, :amendable, :amendment, :emendation, :current_user, :user_group, :image, :attachment

      def allowed_to_accept?
        amendable.editable_by?(current_user)
      end

      def amendable_params
        amendable.slice(*emendation_params.keys)
      end

      def emendation_params
        {
          title: title_with_hashtags,
          body: body_with_hashtags,
          category: form.category,
          area_scope: form.area_scope,
          address: form.address,
          latitude: form.latitude,
          longitude: form.longitude
        }
      end

      # Prevent PaperTrail from creating an additional version
      # in the amendment multi-step creation process (step 1: create)
      #
      # A first version will be created in step 4: publish
      # for diff rendering in the amendment control version
      def create_emendation!
        PaperTrail.request(enabled: false) do
          @emendation = Decidim.traceability.perform_action!(
            :create,
            amendable.class,
            current_user,
            visibility: "public-only"
          ) do
            emendation = amendable.class.new(amendable_params)
            emendation.component = amendable.component
            emendation.add_author(current_user, user_group)
            emendation.save!

            @attached_to = emendation
            create_image if process_image?
            create_attachment if process_attachments?

            emendation
          end
        end
      end

      def create_amendment!
        @amendment = Decidim::Amendment.create!(
          amender: current_user,
          amendable: amendable,
          emendation: @emendation,
          state: "draft"
        )
      end

      # This will be the PaperTrail version that gets compared to the amended
      # proposal.
      def publish_emendation
        Decidim.traceability.perform_action!(
          "publish",
          emendation,
          current_user,
          visibility: "public-only"
        ) do
          emendation.update(emendation_params.merge(published_at: Time.current))
        end
      end

      def update_amendable!
        if allowed_to_accept?
          pending_changes = {}
          pending_changes[:pending_image] = image if image.present?
          pending_changes[:pending_attachments] = [attachment] if attachment.present?

          @amendment = Decidim.traceability.update!(
            @amendment,
            @current_user,
            { state: "accepted" },
            visibility: "public-only"
          )
          @amendable = Decidim.traceability.update!(
            @amendable,
            @current_user,
            emendation_params.merge(pending_changes),
            visibility: "public-only"
          )
          @amendable.add_coauthor(@current_user, user_group: @user_group)

          @attached_to = @amendable
          if image.present?
            @amendable.image.destroy!
            create_image
          end
          if attachment.present?
            @amendable.actual_attachments.destroy_all
            create_attachment
          end
        else
          @amendment.update(state: "evaluating")
        end
      end

      def notify_emendation_state_change!
        emendation.process_amendment_state_change!
      end

      def notify_amendable_authors_and_followers
        Decidim::EventsManager.publish(
          event: "decidim.events.amendments.amendment_created",
          event_class: Decidim::Amendable::AmendmentCreatedEvent,
          resource: amendable,
          affected_users: amendable.notifiable_identities,
          followers: amendable.followers - amendable.notifiable_identities
        )
      end

      def notify_amendable_and_emendation_authors_and_followers
        affected_users = emendation.authors + @amendable.notifiable_identities
        followers = emendation.followers + @amendable.followers - affected_users

        Decidim::EventsManager.publish(
          event: "decidim.events.amendments.amendment_accepted",
          event_class: Decidim::Amendable::AmendmentAcceptedEvent,
          resource: emendation,
          affected_users: affected_users.uniq,
          followers: followers.uniq
        )
      end
    end
  end
end
