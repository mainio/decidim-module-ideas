# frozen_string_literal: true

module Decidim
  module Ideas
    module Admin
      # A command with all the business logic when a user creates a new idea.
      class CreateIdea < Decidim::Command
        include ::Decidim::AttachmentMethods
        include GalleryMethods
        include HashtagsMethods
        include ImageMethods

        # Public: Initializes the command.
        #
        # form - A form object with the params.
        def initialize(form, current_user)
          @form = form
          @current_user = current_user
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid, together with the idea.
        # - :invalid if the form wasn't valid and we couldn't proceed.
        #
        # Returns nothing.
        def call
          return broadcast(:invalid) if form.invalid?

          # For checking the attachment validations
          @attached_to = organization
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

          transaction do
            create_idea
            @attached_to = idea
            create_image if process_image?
            create_attachment if process_attachments?
            send_notification
          end

          broadcast(:ok, idea)
        end

        private

        attr_reader :form, :idea, :image, :attachment

        def create_idea
          @idea = Decidim::Ideas::IdeaBuilder.create(
            attributes: attributes,
            author: @current_user,
            user_group_author: user_group,
            action_user: form.current_user
          )
          @attached_to = @idea
        end

        def user_group
          @user_group ||= Decidim::UserGroup.find_by(organization: organization, id: form.user_group_id)
        end

        def organization
          @organization ||= @current_user.organization
        end

        def attributes
          {
            title: title_with_hashtags,
            body: body_with_hashtags,
            category: form.category,
            area_scope: form.area_scope,
            component: form.component,
            address: form.address,
            latitude: form.latitude,
            longitude: form.longitude,
            published_at: Time.current
          }
        end

        def send_notification
          Decidim::EventsManager.publish(
            event: "decidim.events.ideas.idea_published",
            event_class: Decidim::Ideas::PublishIdeaEvent,
            resource: idea,
            followers: @idea.participatory_space.followers,
            extra: {
              participatory_space: true
            }
          )
        end
      end
    end
  end
end
