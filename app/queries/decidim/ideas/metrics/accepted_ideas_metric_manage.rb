# frozen_string_literal: true

module Decidim
  module Ideas
    module Metrics
      class AcceptedIdeasMetricManage < Decidim::Ideas::Metrics::IdeasMetricManage
        def metric_name
          "accepted_ideas"
        end

        private

        def query
          return @query if @query

          spaces = Decidim.participatory_space_manifests.flat_map do |manifest|
            manifest.participatory_spaces.call(@organization).public_spaces
          end
          components = Decidim::Component.where(participatory_space: spaces).published
          @query = Decidim::Ideas::Idea.where(component: components).joins(:component)
                                       .left_outer_joins(:category)
          @query = @query.where(decidim_ideas_ideas: { created_at: ..end_time }).accepted
          @query = @query.group("decidim_categorizations.decidim_category_id", :participatory_space_type, :participatory_space_id)
          @query
        end

        def quantity
          @quantity ||= query.where(decidim_ideas_ideas: { created_at: start_time.. }).count
        end
      end
    end
  end
end
