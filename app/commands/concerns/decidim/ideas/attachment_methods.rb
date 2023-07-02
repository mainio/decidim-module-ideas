# frozen_string_literal: true

module Decidim
  module Ideas
    # A module with all the attachment common methods
    module AttachmentMethods
      include Decidim::AttachmentMethods

      private

      def build_attachment
        @form.add_actual_attachments.compact_blank.each_with_index do |form_attachment, ind|
          @attachment = Decidim::Ideas::Attachment.new(
            attached_to: @attached_to, # Keep first
            title: { I18n.locale.to_s => form_attachment["title"] },
            file: form_attachment["file"],
            weight: 1 + ind
          )
        end
      end

      def create_attachment(*)
        attachment.attached_to = @attached_to
        attachment.save!
      end

      def attachment_removed?
        return false unless attachment_allowed?

        @form.actual_attachments.blank?
      end

      def attachment_present?
        return false unless attachment_allowed?

        @form.add_actual_attachments.compact_blank.present?
      end

      def attachment_file_uploaded?
        return false unless attachment_present?

        form_attachment = @form.add_actual_attachments.first
        return unless form_attachment

        form_attachment["file"].present?
      end

      def attachment_allowed?
        @form.current_component.settings.attachments_allowed?
      end
    end
  end
end
