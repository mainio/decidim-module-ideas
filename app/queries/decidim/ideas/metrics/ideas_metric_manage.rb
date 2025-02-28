# frozen_string_literal: true

module Decidim
  module Ideas
    module Metrics
      class IdeasMetricManage < Decidim::MetricManage
        def metric_name
          "ideas"
        end

        def save
          return @registry if @registry

          @registry = []
          cumulative.each do |key, cumulative_value|
            next if cumulative_value.zero?

            quantity_value = quantity[key] || 0
            category_id, space_type, space_id = key
            record = Decidim::Metric.find_or_initialize_by(day: @day.to_s, metric_type: @metric_name,
                                                           organization: @organization, decidim_category_id: category_id,
                                                           participatory_space_type: space_type, participatory_space_id: space_id)
            record.assign_attributes(cumulative: cumulative_value, quantity: quantity_value)
            @registry << record
          end
          @registry.each(&:save!)
          @registry
        end

        private

        def query
          return @query if @query

          spaces = Decidim.participatory_space_manifests.flat_map do |manifest|
            manifest.participatory_spaces.call(@organization)
          end
          components = Decidim::Component.where(participatory_space: spaces).published
          @query = Decidim::Ideas::Idea.where(component: components).joins(:component)
                                       .left_outer_joins(:category)
          @query = @query.where(decidim_ideas_ideas: { published_at: ..end_time }).except_withdrawn.not_hidden
          @query = @query.group("decidim_categorizations.decidim_category_id",
                                :participatory_space_type,
                                :participatory_space_id)
          @query
        end

        def quantity
          @quantity ||= query.where(decidim_ideas_ideas: { published_at: start_time.. }).count
        end
      end
    end
  end
end
