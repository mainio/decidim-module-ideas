# frozen_string_literal: true

module Decidim
  module Ideas
    # A command with all the business logic when a user updates a idea.
    class UpdateIdea < Rectify::Command
      include ::Decidim::Ideas::AttachmentMethods
      include ::Decidim::Ideas::ImageMethods
      include HashtagsMethods

      # Public: Initializes the command.
      #
      # form         - A form object with the params.
      # current_user - The current user.
      # idea - the idea to update.
      def initialize(form, current_user, idea)
        @form = form
        @current_user = current_user
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
        return broadcast(:invalid) unless idea.editable_by?(current_user)
        return broadcast(:invalid) if idea_limit_reached?

        @idea.image.destroy! if @idea.image.present? && (process_image? || image_removed?)
        if process_image?
          build_image
          return broadcast(:invalid) if image_invalid?
        end

        @idea.actual_attachments.destroy_all if process_attachments? || attachment_removed?
        if process_attachments?
          build_attachment
          return broadcast(:invalid) if attachment_invalid?
        end

        transaction do
          if @idea.draft?
            update_draft
          else
            update_idea
          end
          create_image if process_image?
          create_attachment if process_attachments?
        end

        broadcast(:ok, idea)
      end

      private

      attr_reader :form, :idea, :current_user, :image, :attachment

      # Prevent PaperTrail from creating an additional version
      # in the idea multi-step creation process (step 3: complete)
      #
      # A first version will be created in step 4: publish
      # for diff rendering in the idea control version
      def update_draft
        PaperTrail.request(enabled: false) do
          @idea.update(attributes)
          @idea.coauthorships.clear
          @idea.add_coauthor(current_user, user_group: user_group)
        end
      end

      def update_idea
        @idea = Decidim.traceability.update!(
          @idea,
          current_user,
          attributes,
          visibility: "public-only"
        )
        @idea.coauthorships.clear
        @idea.add_coauthor(current_user, user_group: user_group)
      end

      def attributes
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

      def idea_limit_reached?
        idea_limit = form.current_component.settings.idea_limit

        return false if idea_limit.zero?

        if user_group
          user_group_ideas.count >= idea_limit
        else
          current_user_ideas.count >= idea_limit
        end
      end

      def user_group
        @user_group ||= Decidim::UserGroup.find_by(organization: organization, id: form.user_group_id)
      end

      def organization
        @organization ||= current_user.organization
      end

      def current_user_ideas
        Idea.from_author(current_user).where(component: form.current_component).published.where.not(id: idea.id).except_withdrawn
      end

      def user_group_ideas
        Idea.from_user_group(user_group).where(component: form.current_component).published.where.not(id: idea.id).except_withdrawn
      end
    end
  end
end
