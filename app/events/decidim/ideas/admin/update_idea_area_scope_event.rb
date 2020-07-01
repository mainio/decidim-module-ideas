# frozen-string_literal: true

module Decidim
  module Ideas
    module Admin
      class UpdateIdeaAreaScopeEvent < Decidim::Events::SimpleEvent
        include Decidim::Events::AuthorEvent
      end
    end
  end
end
