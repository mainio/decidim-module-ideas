# frozen_string_literal: true

module Decidim
  module Ideas
    # A form object to be used when public users want to create an idea.
    class IdeaForm < Decidim::Form
      include Decidim::AttachmentAttributes
      include Decidim::HasTaxonomyFormAttributes

      mimic :idea

      attribute :title, String
      attribute :body, String
      attribute :terms_agreed, Boolean
      attribute :address, String
      attribute :latitude, Float
      attribute :longitude, Float

      # The attachment attribute is needed for the form builder.
      attribute :attachment, Decidim::AttachmentForm
      attachments_attribute :photos
      attachments_attribute :documents
      attribute :remove_photos, Boolean, default: false
      attribute :remove_documents, Boolean, default: false

      validates :terms_agreed, presence: true
      validates :title, presence: true, idea_length: {
        minimum: 5,
        maximum: ->(record) { record.component.settings.idea_title_length }
      }
      validates :body, presence: true, idea_length: {
        minimum: 15,
        maximum: ->(record) { record.component.settings.idea_length }
      }
      validates :address, geocoding: true, if: ->(form) { Decidim.geocoder.present? && form.needs_geocoding? }

      validate :idea_length

      alias component current_component
      alias organization current_organization

      def map_model(model)
        self.photos = [model.image].compact
        self.documents = model.actual_attachments

        self.terms_agreed = true unless model.new_record?

        self.taxonomies = model.taxonomies.pluck(:id) if model.taxonomies.any?
      end

      # In Windows, the front-end form calculates Windows line breaks (\r\n) as
      # a single character which can lead to situations where the user can
      # submit the "too long" text but the backend rejects it, because all those
      # characters are calculated as a single character in the backend.
      def body
        orig_body = super
        return orig_body if orig_body.blank?

        orig_body.gsub("\r", "")
      end

      # Finds the taxonomy filters for the component.
      #
      # Returns a [Decidim::TaxonomyFilter]
      def taxonomy_filters
        @taxonomy_filters ||= begin
          filter_ids = current_component.settings.taxonomy_filters.map(&:to_i)
          Decidim::TaxonomyFilter.where(id: filter_ids)
        end
      end

      def needs_geocoding?
        return false unless has_address?
        return false if latitude.present? && longitude.present?
        return false if address.blank?

        true
      end

      def has_address?
        current_component.settings.geocoding_enabled?
      end

      def areas_enabled?
        current_component.settings.geocoding_enabled?
      end

      private

      def idea_length
        return unless body.presence

        length = current_component.settings.idea_length
        errors.add(:body, :too_long, count: length) if body.length > length
      end
    end
  end
end
