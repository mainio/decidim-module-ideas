# frozen_string_literal: true

module Decidim
  module Ideas
    # A form object used to create image attachments.
    #
    class ImageAttachmentForm < Form
      attribute :title, String
      attribute :file
      attribute :remove_file, Boolean, default: false

      mimic :idea_image_attachment

      validates :title, presence: true, if: ->(form) { form.file.present? }

      validates :file, passthru: { to: Decidim::Ideas::Attachment }, if: ->(form) { form.file.present? }

      alias component current_component
      alias organization current_organization

      def map_model(model)
        self.remove_file = false
      end
    end
  end
end
