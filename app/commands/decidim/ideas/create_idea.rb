# frozen_string_literal: true

module Decidim
  module Ideas
    # A command with all the business logic when a user creates a new idea.
    class CreateIdea < Decidim::Command
      include ::Decidim::Ideas::AttachmentMethods
      include ::Decidim::Ideas::ImageMethods
      include HashtagsMethods

      # Public: Initializes the command.
      #
      # form         - A form object with the params.
      # current_user - The current user.
      # coauthorships - The coauthorships of the idea.
      def initialize(form, current_user, coauthorships = nil)
        @form = form
        @current_user = current_user
        @coauthorships = coauthorships
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when everything is valid, together with the idea.
      # - :invalid if the form wasn't valid and we couldn't proceed.
      #
      # Returns nothing.
      # rubocop:disable Metrics/CyclomaticComplexity
      def call
        return broadcast(:invalid) if form.invalid?

        if idea_limit_reached?
          form.errors.add(:base, I18n.t("decidim.ideas.new.limit_reached"))
          return broadcast(:invalid)
        end

        # For checking the attachment validations
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
          create_idea
          @attached_to = idea
          create_image if process_image?
          create_attachment if process_attachments?
        end

        broadcast(:ok, idea)
      end
      # rubocop:enable Metrics/CyclomaticComplexity

      private

      attr_reader :form, :idea, :image, :attachment

      # Prevent PaperTrail from creating an additional version
      # in the idea multi-step creation process (step 1: create)
      #
      # A first version will be created in step 4: publish
      # for diff rendering in the idea version control
      def create_idea
        PaperTrail.request(enabled: false) do
          @idea = Decidim.traceability.perform_action!(
            :create,
            Decidim::Ideas::Idea,
            @current_user,
            visibility: "public-only"
          ) do
            idea = Idea.new(
              component: form.current_component,
              title: title_with_hashtags,
              body: body_with_hashtags,
              category: form.category,
              area_scope: form.area_scope,
              address: form.address,
              latitude: form.latitude,
              longitude: form.longitude
            )
            idea.add_coauthor(@current_user, user_group:)
            idea.save!
            idea
          end
        end
      end

      def idea_limit_reached?
        return false if @coauthorships.present?

        idea_limit = form.current_component.settings.idea_limit

        return false if idea_limit.zero?

        if user_group
          user_group_ideas.count >= idea_limit
        else
          current_user_ideas.count >= idea_limit
        end
      end

      def user_group
        @user_group ||= Decidim::UserGroup.find_by(organization:, id: form.user_group_id)
      end

      def organization
        @organization ||= @current_user.organization
      end

      def current_user_ideas
        Idea.from_author(@current_user).where(component: form.current_component).except_withdrawn
      end

      def user_group_ideas
        Idea.from_user_group(@user_group).where(component: form.current_component).except_withdrawn
      end
    end
  end
end
