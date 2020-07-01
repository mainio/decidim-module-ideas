# frozen_string_literal: true

module Decidim
  module Ideas
    module Admin
      # A command with all the business logic when a user updates a idea.
      class UpdateIdea < Rectify::Command
        include ::Decidim::AttachmentMethods
        include GalleryMethods
        include HashtagsMethods

        # Public: Initializes the command.
        #
        # form         - A form object with the params.
        # idea - the idea to update.
        def initialize(form, idea)
          @form = form
          @idea = idea
          @attached_to = idea
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid, together with the idea.
        # - :invalid if the form wasn't valid and we couldn't proceed.
        #
        # Returns nothing.
        def call
          return broadcast(:invalid) if form.invalid?

          if process_attachments?
            @idea.attachments.destroy_all

            build_attachment
            return broadcast(:invalid) if attachment_invalid?
          end

          if process_gallery?
            build_gallery
            return broadcast(:invalid) if gallery_invalid?
          end

          transaction do
            update_idea
            update_idea_author
            create_attachment if process_attachments?
            create_gallery if process_gallery?
            photo_cleanup!
          end

          broadcast(:ok, idea)
        end

        private

        attr_reader :form, :idea, :attachment, :gallery

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

        def update_idea_author
          idea.coauthorships.clear
          idea.add_coauthor(form.author)
          idea.save!
          idea
        end
      end
    end
  end
end
