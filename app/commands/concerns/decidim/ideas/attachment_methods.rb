# frozen_string_literal: true

module Decidim
  module Ideas
    # A module with all the attachment common methods
    module AttachmentMethods
      include Decidim::AttachmentMethods

      private

      def build_attachment
        attachments = @form.add_actual_attachments.compact_blank
        # Array is [signed_id, title, signed_id, title, ...]
        attachments.each_slice(2).with_index do |(signed_id, title), ind|
          next if signed_id.blank?

          blob = ActiveStorage::Blob.find_signed(signed_id)
          next unless blob

          @attachment = Decidim::Ideas::Attachment.new(
            attached_to: @attached_to,
            title: { I18n.locale.to_s => title.to_s },
            file: blob,
            content_type: blob.content_type,
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

        @form.remove_actual_attachments
      end

      def attachment_present?
        return false unless attachment_allowed?

        @form.add_actual_attachments.compact_blank.present?
      end

      def attachment_file_uploaded?
        return false unless attachment_present?

        attachments = @form.add_actual_attachments.compact_blank
        signed_id = attachments.first
        signed_id.present? && ActiveStorage::Blob.find_signed(signed_id).present?
      rescue ActiveSupport::MessageVerifier::InvalidSignature
        false
      end

      def attachment_allowed?
        @form.current_component.settings.attachments_allowed?
      end
    end
  end
end
