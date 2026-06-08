# frozen_string_literal: true

module Decidim
  module Ideas
    # A module with all the image attachment common methods
    module ImageMethods
      private

      def build_image
        images = @form.add_images.compact_blank
        signed_id = images[0]
        title = images[1].to_s
        blob = ActiveStorage::Blob.find_signed(signed_id)

        @image = Decidim::Ideas::Attachment.new(
          attached_to: @attached_to,
          title: { I18n.locale.to_s => title },
          file: blob,
          content_type: blob.content_type,
          weight: 0
        )
      end

      def image_invalid?
        if image.invalid? && image.errors.has_key?(:file)
          @form.image.errors.add :file, image.errors[:file]
          true
        end
      end

      def image_removed?
        return false unless image_allowed?

        @form.remove_images
      end

      def image_present?
        return false unless image_allowed?

        @form.add_images.compact_blank.present?
      end

      def create_image
        image.attached_to = @attached_to
        image.save!
      end

      def image_allowed?
        @form.current_component.settings.image_allowed?
      end

      def process_image?
        image_allowed? && image_present?
      end
    end
  end
end
