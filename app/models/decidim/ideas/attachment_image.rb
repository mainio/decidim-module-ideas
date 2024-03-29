# frozen_string_literal: true

module Decidim
  module Ideas
    # In order to pass the correct upload types for validation, we need to mount
    # different uploaders for the image and the file/document attachment.
    class AttachmentImage < ::Decidim::Ideas::BaseAttachment
      self.table_name = :decidim_attachments

      validates_upload :file, uploader: Decidim::Ideas::ImageUploader
    end
  end
end
