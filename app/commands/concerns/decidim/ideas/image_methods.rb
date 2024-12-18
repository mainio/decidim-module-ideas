# frozen_string_literal: true

module Decidim
  module Ideas
    # A module with all the image attachment common methods
    module ImageMethods
      private

      def build_image
        form_image = @form.add_images.compact_blank.first
        @image = Decidim::Ideas::Attachment.new(
          attached_to: @attached_to, # Keep first
          title: { I18n.locale.to_s => form_image["title"] },
          file: form_image["file"],
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

        @form.images.blank?
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
