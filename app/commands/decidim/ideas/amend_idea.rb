# frozen_string_literal: true

module Decidim
  module Ideas
    # A command with all the business logic when amends an idea.
    class AmendIdea < Decidim::Command
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
      # rubocop:disable Metrics/PerceivedComplexity
      def call
        return broadcast(:invalid) if form.invalid?

        @attached_to = form.organization
        attachments_invalid = false
        if process_image?
          build_image
          attachments_invalid ||= image_invalid?
        end
        if process_attachments?
          build_attachment
          attachments_invalid ||= attachment_invalid?
        end
        return broadcast(:invalid) if attachments_invalid

        @attached_to = nil

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
      # rubocop:enable Metrics/PerceivedComplexity

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
      # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
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

            # When the emendation record is created with the author (which is
            # required), the author is automatically added as a follower to the
            # idea. This happens because Decidim::Coauthorship has a callback
            # on the create action which adds the coauthors automatically as
            # followers. With ideas, we don't want this behavior because this
            # would lead the emendation record becoming visible in the user's
            # follows list which can be quite confusing as these are only
            # records that store the full version history of the idea
            # amendments.
            emendation.follows.destroy_all

            @attached_to = emendation
            if process_image?
              create_image
            elsif !image_removed? && amendable.image.present?
              title = if @form.image.title.blank?
                        amendable.image.title if title.blank?
                      else
                        { I18n.locale.to_s => @form.image.title }
                      end

              Decidim::Ideas::Attachment.create!(
                attached_to: emendation, # Keep first
                title:,
                file: amendable.image.file,
                weight: 0
              )
            end
            if process_attachments?
              create_attachment
            elsif !attachment_removed? && amendable.actual_attachments.any?
              title = if @form.attachment.title.blank?
                        amendable.actual_attachments.first.title
                      else
                        { I18n.locale.to_s => @form.attachment.title }
                      end

              Decidim::Ideas::Attachment.create!(
                attached_to: emendation, # Keep first
                title:,
                file: amendable.actual_attachments.first.file,
                weight: 1
              )
            end

            emendation
          end
        end
      end
      # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

      def create_amendment!
        @amendment = Decidim::Amendment.create!(
          amender: current_user,
          amendable:,
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
          @amendable.image.destroy! if @amendable.image.present?
          if emendation.image.present?
            @image = Decidim::Ideas::Attachment.create!(
              attached_to: @amendable, # Keep first
              title: emendation.image.title,
              file: emendation.image.file&.blob,
              weight: 0
            )
          end
          @amendable.actual_attachments.destroy_all
          if emendation.actual_attachments.any?
            @attachment = Decidim::Ideas::Attachment.create!(
              attached_to: @amendable, # Keep first
              title: emendation.actual_attachments.first.title,
              file: emendation.actual_attachments.first.file&.blob,
              weight: 1
            )
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
