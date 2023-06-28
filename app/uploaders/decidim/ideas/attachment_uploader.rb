# frozen_string_literal: true

module Decidim
  module Ideas
    # This class deals with uploading attachments related to an idea.
    # We cannot extend Decidim::AttachmentUploader because we need to redefine
    # some of the methods.
    #
    # Carrierwave does not allow to do this. In case we deleted e.g. versions or
    # processors for redefinitions, they would also disappear from the parent
    # uploader.
    class AttachmentUploader < ::Decidim::ApplicationUploader
      set_variants do
        {
          default: { auto_orient: true, strip: true },
          thumbnail: { resize_to_fill: [860, 340], auto_orient: true, strip: true },
          big: { resize_to_limit: [nil, 1000], auto_orient: true, strip: true },
          main: { resize_to_fill: [1480, 740], auto_orient: true, strip: true }
        }
      end

      def validable_dimensions
        true
      end

      def extension_allowlist
        Decidim.organization_settings(model).upload_allowed_file_extensions
      end

      # CarrierWave automatically calls this method and validates the content
      # type fo the temp file to match against any of these options.
      def content_type_allowlist
        Decidim.organization_settings(model).upload_allowed_content_types
      end

      def max_image_height_or_width
        8000
      end

      protected

      # Checks if the file is an image based on the content type. We need this so
      # we only create different versions of the file when it's an image.
      #
      # new_file - The uploaded file.
      #
      # Returns a Boolean.
      def image?(new_file)
        content_type = model.content_type || new_file.content_type
        content_type.to_s.start_with? "image"
      end
    end
  end
end
