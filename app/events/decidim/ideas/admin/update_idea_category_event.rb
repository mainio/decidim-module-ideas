# frozen_string_literal: true

module Decidim
  module Ideas
    module Admin
      class UpdateIdeaCategoryEvent < Decidim::Events::SimpleEvent
        include Decidim::Events::AuthorEvent
      end
    end
  end
end
