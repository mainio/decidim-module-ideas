# frozen_string_literal: true

module Decidim
  module Ideas
    # A custom version record for the paper trail versions
    class IdeaVersion < ::ActiveRecord::Base
      include PaperTrail::VersionConcern

      def related_changes
        value = super
        return {} unless value
        return {} if value.empty?

        PaperTrail.serializer.load(value)
      end
    end
  end
end
