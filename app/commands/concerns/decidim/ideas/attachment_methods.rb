# frozen_string_literal: true

module Decidim
  module Ideas
    # A module with all the attachment common methods
    module AttachmentMethods
      include Decidim::AttachmentMethods

      private

      def build_attachment
        @attachment = Decidim::Ideas::Attachment.new(
          title: @form.attachment.title,
          file: @form.attachment.file,
          attached_to: @attached_to,
          weight: 1
        )
      end

      def attachment_present?
        @form.attachment.present? && @form.attachment.file.present?
      end
    end
  end
end
