# frozen_string_literal: true

module Decidim
  module Ideas
    # This class deals with uploading attachments related to an idea.
    class AttachmentUploader < ::Decidim::AttachmentUploader
      # Redefine the :strip processor for not to lose the exif data before
      # the orientate processor has run.
      processors.delete_if { |p| p[0] == :strip }

      process :orientate, if: :image?
      process :strip # Redefine the :strip processor AFTER :orientate

      # Redefine the :thumbnail version
      versions.delete(:thumbnail)
      version :thumbnail, if: :image? do
        process resize_to_fill: [860, 340]
      end

      version :main, if: :image? do
        process resize_to_fill: [1480, 740]
      end

      private

      # Flips the image to be in correct orientation based on its Exif
      # orientation metadata.
      def orientate
        manipulate! do |img|
          img.tap(&:auto_orient)
          img = yield(img) if block_given?
          img
        end
      end
    end
  end
end
