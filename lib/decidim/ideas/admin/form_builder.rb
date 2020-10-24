# frozen_string_literal: true

module Decidim
  module Ideas
    module Admin
      class FormBuilder < Decidim::Admin::FormBuilder
        # We only want to display the top-level categories.
        def categories_for_select(scope)
          sorted_main_categories = scope.includes(:subcategories).sort_by do |category|
            [category.weight, translated_attribute(category.name, category.participatory_space.organization)]
          end

          sorted_main_categories.flat_map do |category|
            parent = [[translated_attribute(category.name, category.participatory_space.organization), category.id]]

            parent
          end
        end
      end
    end
  end
end
