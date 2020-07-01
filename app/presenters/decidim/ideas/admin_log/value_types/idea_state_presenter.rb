# frozen_string_literal: true

module Decidim
  module Ideas
    module AdminLog
      module ValueTypes
        class IdeaStatePresenter < Decidim::Log::ValueTypes::DefaultPresenter
          def present
            return unless value

            h.t(value, scope: "decidim.ideas.admin.idea_answers.edit", default: value)
          end
        end
      end
    end
  end
end
