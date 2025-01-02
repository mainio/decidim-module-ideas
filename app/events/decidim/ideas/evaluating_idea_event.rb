# frozen_string_literal: true

module Decidim
  module Ideas
    class EvaluatingIdeaEvent < Decidim::Events::SimpleEvent
      def event_has_roles?
        true
      end
    end
  end
end
