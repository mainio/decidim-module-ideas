# frozen_string_literal: true

module Decidim
  module Ideas
    # The data store for a Idea in the Decidim::Ideas component.
    class Idea < Ideas::ApplicationRecord
      include Decidim::Resourceable
      include Decidim::Coauthorable
      include Decidim::HasComponent
      include Decidim::Ideas::AreaScopable
      # include Decidim::ScopableResource
      include Decidim::HasReference
      include Decidim::HasCategory
      include Decidim::Reportable
      include Decidim::HasAttachments
      include Decidim::Followable
      include Decidim::Ideas::CommentableIdea
      include Decidim::Searchable
      include Decidim::Randomable
      include Decidim::Ideas::Traceability
      include Decidim::Loggable
      include Decidim::Fingerprintable
      include Decidim::DownloadYourData
      include Decidim::Amendable
      include Decidim::FilterableResource
      include Decidim::Favorites::Favoritable

      has_paper_trail(
        versions: { class_name: "Decidim::Ideas::IdeaVersion" },
        meta: {
          related_changes: proc { |idea| idea.generate_related_changes }
        }
      )

      attr_accessor :pending_image, :pending_attachments

      POSSIBLE_STATES = %w(not_answered evaluating accepted rejected withdrawn).freeze

      fingerprint fields: [:title, :body]

      amendable(
        fields: [:title, :body],
        form: "Decidim::Ideas::IdeaForm"
      )

      component_manifest_name "ideas"

      # Redefine the attachments association so that we can take control of the
      # uploaders related to the attachments.
      has_many :attachments,
               class_name: "Decidim::Ideas::Attachment",
               dependent: :destroy,
               inverse_of: :attached_to,
               as: :attached_to

      validates :title, :body, presence: true

      geocoded_by :address, http_headers: ->(idea) { { "Referer" => idea.component.organization.host } }

      scope :answered, -> { where.not(answered_at: nil) }
      scope :not_answered, -> { where(answered_at: nil) }

      scope :state_not_published, -> { where(state_published_at: nil) }
      scope :state_published, -> { where.not(state_published_at: nil).where.not(state: nil) }

      scope :accepted, -> { state_published.where(state: "accepted") }
      scope :rejected, -> { state_published.where(state: "rejected") }
      scope :evaluating, -> { state_published.where(state: "evaluating") }
      scope :withdrawn, -> { where(state: "withdrawn") }
      scope :except_rejected, -> { where.not(state: "rejected").or(state_not_published) }
      scope :except_withdrawn, -> { where.not(state: "withdrawn").or(where(state: nil)) }
      scope :drafts, -> { where(published_at: nil) }
      scope :published, -> { where.not(published_at: nil) }
      scope :participants_origin, lambda {
        where.not(coauthorships_count: 0)
             .joins(:coauthorships)
             .where.not(decidim_coauthorships: { decidim_author_type: "Decidim::Organization" })
      }
      scope :user_group_origin, lambda {
        where.not(coauthorships_count: 0)
             .joins(:coauthorships)
             .where(decidim_coauthorships: { decidim_author_type: "Decidim::UserBaseEntity" })
             .where.not(decidim_coauthorships: { decidim_user_group_id: nil })
      }

      scope :with_availability, lambda { |availability_key|
        case availability_key
        when "withdrawn"
          withdrawn
        else
          except_withdrawn
        end
      }

      scope :with_any_area_scope, lambda { |*original_scope_ids|
        scope_ids = original_scope_ids.flatten
        return self if scope_ids.include?("all")

        clean_scope_ids = scope_ids

        conditions = []
        conditions.concat(["? = ANY(decidim_area_scopes.part_of)"] * clean_scope_ids.count) if clean_scope_ids.any?

        includes(:area_scope).joins(
          "LEFT OUTER JOIN decidim_scopes AS decidim_area_scopes ON decidim_area_scopes.id = decidim_ideas_ideas.area_scope_id"
        ).where(Arel.sql(conditions.join(" OR ")).to_s, *clean_scope_ids.map(&:to_i))
      }

      scope_search_multi :with_any_state, [:accepted, :rejected, :evaluating, :state_not_published, :not_answered, :withdrawn]

      acts_as_list scope: :decidim_component_id

      searchable_fields(
        {
          scope_id: :area_scope_id,
          participatory_space: { component: :participatory_space },
          D: :body,
          A: :title,
          datetime: :published_at
        },
        index_on_create: ->(idea) { idea.visible? },
        index_on_update: ->(idea) { idea.visible? }
      )

      def self.log_presenter_class_for(_log)
        Decidim::Ideas::AdminLog::IdeaPresenter
      end

      # Returns a collection scoped by an author.
      # Overrides this method in DownloadYourData to support Coauthorable.
      def self.user_collection(author)
        return unless author.is_a?(Decidim::User)

        joins(:coauthorships)
          .where(decidim_coauthorships: { coauthorable_type: name })
          .where("decidim_coauthorships.decidim_author_id = ? AND decidim_coauthorships.decidim_author_type = ? ", author.id, author.class.base_class.name)
      end

      def self.retrieve_ideas_for(component)
        Decidim::Ideas::Idea.where(component:)
                            .joins(:coauthorships)
                            .where(decidim_coauthorships: { decidim_author_type: "Decidim::UserBaseEntity" })
                            .not_hidden
                            .published
                            .except_withdrawn
      end

      def self.geocoded_data_for(component)
        locale = Arel::Nodes.build_quoted(I18n.locale.to_s).to_sql

        with_geocoded_area_scopes_for(component).pluck(
          :id,
          :title,
          :body,
          Arel.sql("CASE WHEN CHAR_LENGTH(decidim_ideas_ideas.address::text) > 0 THEN decidim_ideas_ideas.address ELSE area_scopes.name->>#{locale} END"),
          Arel.sql("CASE WHEN decidim_ideas_ideas.latitude IS NOT NULL THEN decidim_ideas_ideas.latitude ELSE scope_coordinates.latitude END"),
          Arel.sql("CASE WHEN decidim_ideas_ideas.latitude IS NOT NULL THEN decidim_ideas_ideas.longitude ELSE scope_coordinates.longitude END")
        )
      end

      def self.area_scope_coordinates_for(component)
        component.settings.area_scope_coordinates.to_h do |scope_id, coords|
          latlng = coords.split(",")
          next [scope_id.to_s.to_i, nil] if latlng.length < 2

          [scope_id.to_s.to_i, [latlng[0].to_f, latlng[1].to_f]]
        end.compact
      end

      def self.with_geocoded_area_scopes_for(component)
        # Fetch all the configured area scope coodinates and create a select
        # statement for each scope with its latitude and longitude in order to
        # combine this information with the base query.
        scope_selects = area_scope_coordinates_for(component).map do |scope_id, coords|
          "SELECT #{scope_id} AS scope_id, #{coords[0]} AS latitude, #{coords[1]} AS longitude"
        end

        # The empty select ensures there is always at least one row for the
        # scope locations so that it will not break even when it is not
        # configured correctly.
        empty_scope_select = "SELECT 0 AS scope_id, 0 AS latitude, 0 AS longitude"
        # The scopes "table" is a virtual scopes table which consists of the
        # unionized scope selects resulting in multiple rows of scope IDs
        # combined with their associated latitude and longitude coordinates.
        scopes_table = ([empty_scope_select] + scope_selects).join(" UNION ALL ")

        joins("LEFT JOIN decidim_scopes AS area_scopes ON area_scopes.id = decidim_ideas_ideas.area_scope_id")
          .joins("LEFT JOIN (#{scopes_table}) AS scope_coordinates ON scope_coordinates.scope_id = area_scopes.id")
      end

      def self.newsletter_participant_ids(component)
        ideas = retrieve_ideas_for(component).uniq

        coauthors_recipients_ids = ideas.map { |p| p.notifiable_identities.pluck(:id) }.flatten.compact.uniq

        commentators_ids = Decidim::Comments::Comment.user_commentators_ids_in(ideas)

        (coauthors_recipients_ids + commentators_ids).flatten.compact.uniq
      end

      def image
        attachments.find_by(weight: 0)
      end

      def attachment
        actual_attachments.first
      end

      def actual_attachments
        attachments.where("weight > 0")
      end

      # All the attachments that are photos for this process.
      #
      # Returns an Array<Attachment>
      def photos
        @photos ||= actual_attachments.select(&:photo?).reject { |p| p == image }
      end

      # All the attachments that are documents for this process.
      #
      # Returns an Array<Attachment>
      def documents
        @documents ||= actual_attachments.includes(:attachment_collection).select(&:document?)
      end

      # Public: Checks if the idea has been published or not.
      #
      # Returns Boolean.
      def published?
        published_at.present?
      end

      # Public: Returns the published state of the idea.
      #
      # Returns Boolean.
      def state
        return amendment.state if emendation?
        return nil unless published_state? || withdrawn?

        super
      end

      # This is only used to define the setter, as the getter will be overriden below.
      alias_attribute :internal_state, :state

      # Public: Returns the internal state of the idea.
      #
      # Returns Boolean.
      def internal_state
        return amendment.state if emendation?

        self[:state]
      end

      # Public: Checks if the organization has published the state for the idea.
      #
      # Returns Boolean.
      def published_state?
        emendation? || state_published_at.present?
      end

      # Public: Checks if the organization has given an answer for the idea.
      #
      # Returns Boolean.
      def answered?
        answered_at.present?
      end

      # Public: Checks if the author has withdrawn the idea.
      #
      # Returns Boolean.
      def withdrawn?
        internal_state == "withdrawn"
      end

      # Public: Checks if the organization has accepted a idea.
      #
      # Returns Boolean.
      def accepted?
        state == "accepted"
      end

      # Public: Checks if the organization has rejected a idea.
      #
      # Returns Boolean.
      def rejected?
        state == "rejected"
      end

      # Public: Checks if the organization has marked the idea as evaluating it.
      #
      # Returns Boolean.
      def evaluating?
        state == "evaluating"
      end

      # Public: Overrides the `reported_content_url` Reportable concern method.
      def reported_content_url
        ResourceLocatorPresenter.new(self).url
      end

      # Public: Overrides the `reported_attributes` Reportable concern method.
      def reported_attributes
        [:title, :body]
      end

      # Checks whether the user can edit the given idea.
      #
      # user - the user to check for authorship
      def editable_by?(user)
        return false if withdrawn?
        return true if draft?

        !published_state? && within_edit_time_limit? && !copied_from_other_component? && created_by?(user)
      end

      # Checks whether the user can withdraw the given idea.
      #
      # user - the user to check for withdrawability.
      def withdrawable_by?(user)
        user && !withdrawn? && authored_by?(user) && !copied_from_other_component?
      end

      # Public: Whether the idea is a draft or not.
      def draft?
        published_at.nil?
      end

      # Checks whether the idea is inside the time window to be editable or not
      # once published.
      def within_edit_time_limit?
        return true if draft?

        limit = updated_at + component.settings.idea_edit_before_minutes.minutes
        Time.current < limit
      end

      # Replicates the same data for a single idea as returned for a collection
      # through the `#geocoded_data_for` method.
      def geocoded_data
        locale = I18n.locale.to_s
        default_locale = I18n.default_locale.to_s

        scope_coordinates = self.class.area_scope_coordinates_for(component)
        idea_scope_coordinates = scope_coordinates[area_scope.id] || []

        [
          id,
          title,
          body,
          address || area_scope.title[locale] || area_scope.title[default_locale],
          latitude || idea_scope_coordinates[0],
          longitude || idea_scope_coordinates[1]
        ]
      end

      # Create i18n ransackers for :title and :body.
      # Create the :search_text ransacker alias for searching from both of these.
      ransacker_text_multi :search_text, [:title, :body]

      # method for sort_link by number of comments
      ransacker :commentable_comments_count do
        query = <<-SQL.squish
        (SELECT COUNT(decidim_comments_comments.id)
         FROM decidim_comments_comments
         WHERE decidim_comments_comments.decidim_commentable_id = decidim_ideas_ideas.id
         AND decidim_comments_comments.decidim_commentable_type = 'Decidim::Ideas::Idea'
         GROUP BY decidim_comments_comments.decidim_commentable_id
         )
        SQL
        Arel.sql(query)
      end

      ransacker :state_published do
        Arel.sql("CASE
          WHEN EXISTS (
            SELECT 1 FROM decidim_amendments
            WHERE decidim_amendments.decidim_emendation_type = 'Decidim::Ideas::Idea'
            AND decidim_amendments.decidim_emendation_id = decidim_ideas_ideas.id
          ) THEN 0
          WHEN state_published_at IS NULL AND answered_at IS NOT NULL THEN 2
          WHEN state_published_at IS NOT NULL THEN 1
          ELSE 0 END
        ")
      end

      ransacker :state do
        Arel.sql("CASE WHEN state = 'withdrawn' THEN 'withdrawn' WHEN state_published_at IS NULL THEN NULL ELSE state END")
      end

      ransacker :id_string do
        Arel.sql(%{cast("decidim_ideas_ideas"."id" as text)})
      end

      ransacker :is_emendation do |_parent|
        query = <<-SQL.squish
        (
          SELECT EXISTS (
            SELECT 1 FROM decidim_amendments
            WHERE decidim_amendments.decidim_emendation_type = 'Decidim::Ideas::Idea'
            AND decidim_amendments.decidim_emendation_id = decidim_ideas_ideas.id
          )
        )
        SQL
        Arel.sql(query)
      end

      def self.ransack(params = {}, options = {})
        IdeaSearch.new(self, params, options)
      end

      def self.ransackable_scopes(_auth_object = nil)
        [:with_availability, :with_any_state, :with_any_area_scope, :with_category]
      end

      def self.export_serializer
        Decidim::Ideas::IdeaSerializer
      end

      def self.data_portability_images(user)
        user_collection(user).map { |p| p.attachments.collect(&:file) }
      end

      # Public: Overrides the `allow_resource_permissions?` Resourceable concern method.
      def allow_resource_permissions?
        component.settings.resources_permissions_enabled
      end

      def process_amendment_state_change!
        return unless %w(accepted rejected evaluating withdrawn).member?(amendment.state)

        PaperTrail.request(enabled: false) do
          update!(
            state: amendment.state,
            state_published_at: Time.current
          )
        end
      end

      # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      def generate_related_changes
        final = {}.tap do |changes|
          if categorization&.saved_changes && categorization.saved_changes["decidim_category_id"].present?
            changes["decidim_category_id"] = categorization.saved_changes["decidim_category_id"]
          end
          if pending_image.present? && pending_image != image
            changes["image"] = [
              { id: image.id, title: image.title },
              { id: pending_image.id, title: pending_image.title }
            ]
          end
          if pending_attachments.present?
            pending_attachments.reject! { |a| attachments.include?(a) }

            attachment_changes = []
            pending_attachments.map do |attachment|
              old = attachments.find_by(weight: attachment.weight)
              old_val = old ? { id: old.id, title: old.title } : nil
              attachment_changes << [
                old_val,
                { id: attachment.id, title: attachment.title }
              ]
            end

            changes["attachments"] = attachment_changes
          end
        end

        return nil if final.empty?

        PaperTrail.serializer.dump(final)
      end
      # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

      private

      def copied_from_other_component?
        linked_resources(:ideas, "copied_from_component").any?
      end
    end
  end
end
