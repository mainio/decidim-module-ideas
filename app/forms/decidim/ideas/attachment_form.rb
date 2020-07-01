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

      validates :file,
        file_size: { less_than_or_equal_to: ->(_record) { Decidim.maximum_attachment_size } },
        file_content_type: {
          allow: [
            %r{image\/jpeg},
            %r{image\/png},
            %r{application\/vnd.oasis.opendocument},
            %r{application\/vnd.ms-},
            %r{application\/msword},
            %r{application\/vnd.ms-word},
            %r{application\/vnd.openxmlformats-officedocument},
            %r{application\/vnd.oasis.opendocument},
            %r{application\/pdf},
            %r{application\/rtf}
          ]
        }
    end
  end
end
