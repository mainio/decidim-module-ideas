# frozen_string_literal: true

module Decidim
  module Ideas
    # In order to control the uploaders related to the idea attachments, we
    # need to take control of the attachment records.
    class Attachment < ::Decidim::Attachment
      self.table_name = :decidim_attachments

      mount_uploader :file, Decidim::Ideas::AttachmentUploader

      def self.translatable_fields_list
        superclass.translatable_fields_list
      end

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
