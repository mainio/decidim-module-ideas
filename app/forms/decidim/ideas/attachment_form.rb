# frozen_string_literal: true

module Decidim
  module Ideas
    # A form object used to create attachments.
    #
    class AttachmentForm < Form
      attribute :title, String
      attribute :file

      mimic :idea_attachment

      validates :title, presence: true, if: ->(form) { form.file.present? }

      validates :file, passthru: { to: Decidim::Ideas::Attachment }, if: ->(form) { form.file.present? }

      alias component current_component
      alias organization current_organization
    end
  end
end
