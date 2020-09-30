# frozen_string_literal: true

module Decidim
  module Ideas
    # A module with all the image attachment common methods
    module ImageMethods
      private

      def build_image
        @image = Decidim::Ideas::Attachment.new(
          title: @form.image.title,
          file: @form.image.file,
          weight: 0,
          attached_to: @attached_to
        )
      end

      def image_invalid?
        if image.invalid? && image.errors.has_key?(:file)
          @form.image.errors.add :file, image.errors[:file]
          true
        end
      end

      def image_present?
        @form.image.present? && @form.image.file.present?
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
