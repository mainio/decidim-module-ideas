# frozen_string_literal: true

module Decidim
  module Ideas
    class IdeaInputSort < Decidim::Core::BaseInputSort
      include Decidim::Core::HasPublishableInputSort
      include Decidim::Core::HasEndorsableInputSort

      graphql_name "IdeaSort"
      description "A type used for sorting ideas"

      argument :id, String, "Sort by ID, valid values are ASC or DESC", required: false
    end
  end
end
