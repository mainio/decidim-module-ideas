# frozen_string_literal: true

module Decidim
  module Ideas
    # In order to control the uploaders related to the idea attachments, we
    # need to take control of the attachment records.
    class Attachment < ::Decidim::Attachment
      self.table_name = :decidim_attachments

      validates_upload :file
      mount_uploader :file, Decidim::Ideas::AttachmentUploader

      # The URL to download the "main" version of the file. Only works with
      # images.
      #
      # Returns String.
      def main_url
        return unless photo?

        file.main.url
      end
    end
  end
end
