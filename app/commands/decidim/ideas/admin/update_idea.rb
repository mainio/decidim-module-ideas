# frozen_string_literal: true

module Decidim
  module Ideas
    module Admin
      # A command with all the business logic when a user updates a idea.
      class UpdateIdea < Rectify::Command
        include ::Decidim::Ideas::AttachmentMethods
        include ::Decidim::Ideas::ImageMethods
        include HashtagsMethods

        # Public: Initializes the command.
        #
        # form         - A form object with the params.
        # idea - the idea to update.
        def initialize(form, current_user, idea)
          @form = form
          @idea = idea
          @current_user = current_user
          @attached_to = idea
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid, together with the idea.
        # - :invalid if the form wasn't valid and we couldn't proceed.
        #
        # Returns nothing.
        # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        def call
          return broadcast(:invalid) if form.invalid?

          # For checking the attachment validations
          attachments_invalid = false
          idea.image.destroy! if idea.image.present? && (process_image? || image_removed?)
          if process_image?
            build_image
            attachments_invalid ||= image_invalid?
          end
          idea.actual_attachments.destroy_all if process_attachments? || attachment_removed?
          if process_attachments?
            build_attachment
            attachments_invalid ||= attachment_invalid?
          end
          return broadcast(:invalid) if attachments_invalid

          transaction do
            update_idea
            update_idea_author
            create_image if process_image?
            create_attachment if process_attachments?
          end

          broadcast(:ok, idea)
        end
        # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

        private

        attr_reader :form, :idea, :image, :attachment

        def update_idea
          Decidim.traceability.update!(
            idea,
            form.current_user,
            title: title_with_hashtags,
            body: body_with_hashtags,
            category: form.category,
            area_scope: form.area_scope,
            address: form.address,
            latitude: form.latitude,
            longitude: form.longitude
          )
        end

        def user_group
          @user_group ||= Decidim::UserGroup.find_by(organization: organization, id: form.user_group_id)
        end

        def organization
          @organization ||= @current_user.organization
        end

        def update_idea_author
          idea.add_coauthor(@current_user, user_group: user_group)
          idea.save!
          idea
        end
      end
    end
  end
end
