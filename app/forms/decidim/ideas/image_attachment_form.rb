# frozen_string_literal: true

module Decidim
  module Ideas
    # A form object used to create image attachments.
    #
    class ImageAttachmentForm < Form
      include Decidim::TranslatableAttributes
      include Decidim::HasUploadValidations

      attribute :title, String
      attribute :file
      attribute :remove_file, Boolean, default: false

      mimic :idea_image_attachment

      validates :title, presence: true, if: ->(form) { form.file.present? }

      validates(
        :file,
        passthru: { to: Decidim::Ideas::AttachmentImage },
        file_size: { less_than_or_equal_to: ->(_form) { 10.megabytes } },
        if: ->(form) { form.file.present? }
      )

      alias component current_component
      alias organization current_organization
      alias image file

      def map_model(model)
        self.remove_file = false
        return unless model

        self.title = translated_attribute(model.title)
      end

      # Needed for the image upload modal
      def url
        "dummy.jpg"
      end
    end
  end
end
