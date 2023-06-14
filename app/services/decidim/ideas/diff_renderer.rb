# frozen_string_literal: true

module Decidim
  module Ideas
    class DiffRenderer < BaseDiffRenderer
      # Renders the diff of the given changeset. Takes into account translatable fields.
      #
      # Returns a Hash, where keys are the fields that have changed and values are an
      # array, the first element being the previous value and the last being the new one.
      def diff
        super.merge(related_changes_diff)
      end

      private

      # Lists which attributes will be diffable and how they should be rendered.
      def attribute_types
        {
          title: :string,
          body: :string,
          area_scope_id: :scope,
          address: :string,
          latitude: :string,
          longitude: :string,
          state: :string
        }
      end

      # Parses the values before parsing the changeset.
      def parse_changeset(attribute, values, type, diff)
        return parse_scope_changeset(attribute, values, type, diff) if type == :scope

        values = parse_values(attribute, values)

        diff.update(
          attribute => {
            type: type,
            label: I18n.t(attribute, scope: i18n_scope),
            old_value: values[0],
            new_value: values[1]
          }
        )
      end

      # Handles which values to use when diffing emendations and
      # normalizes line endings of the :body attribute values.
      # Returns and Array of two Strings.
      def parse_values(attribute, values)
        values = [amended_previous_value(attribute), values[1]] if idea&.emendation?
        values = values.map { |value| normalize_line_endings(value) } if attribute == :body
        values
      end

      # Sets the previous value so the emendation can be compared with the amended idea.
      # If the amendment is being evaluated, returns the CURRENT attribute value of the amended idea;
      # else, returns the attribute value of amended idea at the moment of making the amendment.
      def amended_previous_value(attribute)
        if idea.amendment.evaluating?
          idea.amendable.attributes[attribute.to_s]
        else
          idea.versions.first.changeset[attribute.to_s].first
        end
      end

      # Returns a String with the newline escape sequences normalized.
      def normalize_line_endings(string)
        Decidim::ContentParsers::NewlineParser.new(string, context: {}).rewrite
      end

      def idea
        @idea ||= Idea.find_by(id: version.item_id)
      end

      def related_changes_diff
        {}.tap do |final|
          if (values = version.related_changes["decidim_category_id"])
            old_cat = Decidim::Category.find_by(id: values[0])
            new_cat = Decidim::Category.find_by(id: values[1])
            final[:category_id] = {
              type: :category,
              label: I18n.t(:decidim_category_id, scope: i18n_scope),
              old_value: translated_attribute(old_cat&.name),
              new_value: translated_attribute(new_cat&.name)
            }
          end
        end
      end

      def parse_scope_changeset(attribute, values, type, diff)
        return unless diff

        old_scope = Decidim::Scope.find_by(id: values[0])
        new_scope = Decidim::Scope.find_by(id: values[1])

        diff.update(
          attribute => {
            type: type,
            label: I18n.t(attribute, scope: i18n_scope),
            old_value: old_scope ? translated_attribute(old_scope.name) : "",
            new_value: new_scope ? translated_attribute(new_scope.name) : ""
          }
        )
      end
    end
  end
end
