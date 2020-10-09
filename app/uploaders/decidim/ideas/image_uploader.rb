# frozen_string_literal: true

module Decidim
  module Ideas
    # This class deals with uploading the image attachment related to an idea.
    # This is in order to pass the correct extensions and content types for the
    # image validations. These differ from the "any" type of attachments.
    class ImageUploader < ::Decidim::Ideas::AttachmentUploader
      def extension_whitelist
        %w(jpg jpeg png)
      end

      # CarrierWave automatically calls this method and validates the content
      # type fo the temp file to match against any of these options.
      def content_type_whitelist
        [%r{image\/}]
      end
    end
  end
end
