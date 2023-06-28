# frozen_string_literal: true

module Decidim
  module Ideas
    # In order to control the uploaders related to the idea attachments, we
    # need to take control of the attachment records.
    class Attachment < ::Decidim::Ideas::BaseAttachment
      self.table_name = :decidim_attachments

      validates_upload :file, uploader: Decidim::Ideas::AttachmentUploader
    end
  end
end
