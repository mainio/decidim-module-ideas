# frozen_string_literal: true

module Decidim
  module Ideas
    module Admin
      module FilterableHelper
        def extra_dropdown_submenu_options_items(filter, i18n_scope)
          options = case filter
                    when :state_eq
                      content_tag(:li, filter_link_value(:state_null, true, i18n_scope))
                    end
          [options].compact
        end

        def grouped_filter_taxonomies(filter)
          groups = {}
          filter_ids = filter.taxonomies.keys.map(&:to_i)

          filter.taxonomies.each do |id, node|
            taxonomy = node[:taxonomy]
            parent_id = taxonomy.parent_id

            if parent_id.present? && parent_id != filter.root_taxonomy_id && filter_ids.exclude?(parent_id)
              # This item's parent is not in the filter and not the root — group under parent
              parent = Decidim::Taxonomy.find_by(id: parent_id)
              next unless parent

              groups[parent.id] ||= { taxonomy: parent, children: {} }
              groups[parent.id][:children][id] = node
            else
              groups[id] ||= { taxonomy: taxonomy, children: {} }
            end
          end
          groups
        end
      end
    end
  end
end
