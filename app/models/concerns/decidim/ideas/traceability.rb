# frozen_string_literal: true

require "active_support/concern"

require_dependency "paper_trail/frameworks/active_record"

module Decidim
  module Ideas
    # See Decidim::Traceable
    #
    # This contains the exact same methods without the has_paper_trail
    # definition because we need to customize it on the model. It cannot be
    # overrun because it registers the version callbacks on the model.
    # Therefore, when has_paper_trail is called multiple times, multiple
    # versions would be created on the traceable actions of the model.
    module Traceability
      extend ActiveSupport::Concern

      included do
        delegate :count, to: :versions, prefix: true

        def last_whodunnit
          versions.last.try(:whodunnit)
        end

        def last_editor
          Decidim.traceability.version_editor(versions.last)
        end
      end

      # This is needed for the action logs to work properly. They are only
      # stored against models that implement Decidim::Traceable. However, we
      # cannot directly include that module because we want to modify its
      # functionality.
      def is_a?(klass)
        return true if klass == Decidim::Traceable

        super
      end
    end
  end
end
