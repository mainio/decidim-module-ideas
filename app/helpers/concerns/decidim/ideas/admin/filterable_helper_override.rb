# frozen_string_literal: true

module Decidim
  module Ideas
    module Admin
      module FilterableHelperOverride
        extend ActiveSupport::Concern
        included do
          # Builds a tree of links from Decidim::Admin::Filterable::filters_with_values
          def submenu_options_tree(i18n_ctx = nil)
            i18n_scope = filterable_i18n_scope_from_ctx(i18n_ctx)

            filters_with_values.each_with_object({}) do |(filter, values), hash|
              # Remove type/emendation filter
              next if filter == :is_emendation_true

              link = filter_link_label(filter, i18n_scope)
              hash[link] = if values.is_a?(Array)
                             build_submenu_options_tree_from_array(filter, values, i18n_scope)
                           elsif values.is_a?(Hash)
                             build_submenu_options_tree_from_hash(filter, values, i18n_scope)
                           end
            end
          end
        end
      end
    end
  end
end
