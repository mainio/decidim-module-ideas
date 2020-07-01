# frozen_string_literal: true

module Decidim
  module Ideas
    # A form object used to create image attachments.
    #
    class ImageAttachmentForm < Form
      attribute :title, String
      attribute :file

      mimic :idea_image_attachment

      validates :title, presence: true, if: ->(form) { form.file.present? }

      validates :file,
        file_size: { less_than_or_equal_to: ->(_record) { Decidim.maximum_attachment_size } },
        file_content_type: { allow: ["image/jpeg", "image/png"] }
    end
  end
end
