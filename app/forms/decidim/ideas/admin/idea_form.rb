# frozen_string_literal: true

module Decidim
  module Ideas
    module Admin
      # A form object to be used when admin users want to create a idea.
      class IdeaForm < Decidim::Form
        include Decidim::ApplicationHelper
        include Decidim::AttachmentAttributes

        mimic :idea

        attribute :user_group_id, Integer
        attribute :title, String
        attribute :body, String
        attribute :address, String
        attribute :perform_geocoding, Boolean
        attribute :latitude, Float
        attribute :longitude, Float
        attribute :category_id, Integer
        attribute :sub_category_id, Integer
        attribute :area_scope_id, Integer
        attribute :suggested_hashtags, Array[String]
        attribute :image, Decidim::Ideas::ImageAttachmentForm
        attribute :attachment, Decidim::Ideas::AttachmentForm

        attachments_attribute :images
        attachments_attribute :actual_attachments

        validates :title, presence: true, idea_length: {
          minimum: 5,
          maximum: ->(record) { record.component.settings.idea_title_length }
        }
        validates :body, presence: true, idea_length: {
          minimum: 15,
          maximum: ->(record) { record.component.settings.idea_length }
        }
        validates :address, geocoding: true, if: ->(form) { Decidim.geocoder.present? && form.needs_geocoding? }
        validates :category_id, presence: true, if: ->(form) { form.categories_available? }
        validates :category, presence: true, if: ->(form) { form.category_id.present? }
        validates :area_scope_id, presence: true, if: ->(form) { form.areas_enabled? }
        validates :area_scope, presence: true, if: ->(form) { form.area_scope_id.present? }

        validate :idea_length
        validate :area_scope_belongs_to_parent_scope
        validate :notify_missing_attachment_if_errored

        delegate :categories, to: :current_component

        def map_model(model)
          self.suggested_hashtags = Decidim::ContentRenderers::HashtagRenderer.new(model.body).extra_hashtags.map(&:name).map(&:downcase)

          self.user_group_id = model.user_groups.first&.id
          return unless model.categorization

          model_category = model.category
          return unless model_category

          if model_category.parent_id
            self.category_id = model_category.parent_id
            self.sub_category_id = model_category.id
          else
            self.category_id = model_category.id
          end
        end

        alias component current_component

        # In Windows, the front-end form calculates Windows line breaks (\r\n) as
        # a single character which can lead to situations where the user can
        # submit the "too long" text but the backend rejects it, because all those
        # characters are calculated as a single character in the backend.
        def body
          orig_body = super
          return orig_body if orig_body.blank?

          orig_body.gsub(/\r/, "")
        end

        # Finds the Category from the category_id.
        #
        # Returns a Decidim::Category
        def category
          @category ||= categories.find_by(id: category_id)
        end

        # Finds the top Categories for the component.
        #
        # Returns a [Decidim::Category]
        def top_categories
          @top_categories ||= categories.where(parent_id: nil)
        end

        # Finds the Scope from the given decidim_scope_id.
        #
        # Returns a Decidim::Scope
        def area_scope
          @area_scope ||= current_organization.scopes.find_by(id: attributes["area_scope_id"])
        end

        # Area Scope identifier
        #
        # Returns the area scope identifier related to the idea
        def area_scope_id
          @area_scope_id || area_scope&.id
        end

        def needs_geocoding?
          return false unless perform_geocoding
          return false unless has_address?
          return false if latitude.present? && longitude.present?
          return false if address.blank?

          true
        end

        def has_address?
          current_component.settings.geocoding_enabled?
        end

        def extra_hashtags
          @extra_hashtags ||= (component_automatic_hashtags + suggested_hashtags).uniq
        end

        def suggested_hashtags
          downcased_suggested_hashtags = Array(attributes["suggested_hashtags"]&.map(&:downcase)).to_set
          component_suggested_hashtags.select { |hashtag| downcased_suggested_hashtags.member?(hashtag.downcase) }
        end

        def suggested_hashtag_checked?(hashtag)
          suggested_hashtags.member?(hashtag)
        end

        def areas_enabled?
          current_component.settings.geocoding_enabled?
        end

        def categories_available?
          categories&.any?
        end

        def component_automatic_hashtags
          @component_automatic_hashtags ||= ordered_hashtag_list(current_component.current_settings.automatic_hashtags)
        end

        def component_suggested_hashtags
          @component_suggested_hashtags ||= ordered_hashtag_list(current_component.current_settings.suggested_hashtags)
        end

        private

        def idea_length
          return unless body.presence

          length = current_component.settings.idea_length
          errors.add(:body, :too_long, count: length) if body.length > length
        end

        def area_scope_belongs_to_parent_scope
          return unless area_parent_scope
          return unless area_scope

          errors.add(:area_scope_id, :invalid) unless area_parent_scope.ancestor_of?(area_scope)
        end

        def area_parent_scope
          @area_parent_scope ||= begin
            parent_scope_id = current_component.settings.area_scope_parent_id
            return if parent_scope_id.blank?

            current_organization.scopes.find_by(id: parent_scope_id)
          end
        end

        # This method will add an error to the `attachment` field only if there's
        # any error in any other field. This is needed because when the form has
        # an error, the attachment is lost, so we need a way to inform the user of
        # this problem.
        def notify_missing_attachment_if_errored
          errors.add(:image, :needs_to_be_reattached) if errors.any? && image.present? && image.file.present?
          errors.add(:attachment, :needs_to_be_reattached) if errors.any? && attachment.present? && attachment.file.present?
        end

        def ordered_hashtag_list(string)
          string.to_s.split.reject(&:blank?).uniq.sort_by(&:parameterize)
        end
      end
    end
  end
end
