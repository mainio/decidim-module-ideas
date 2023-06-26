# frozen_string_literal: true

module Decidim
  module Ideas
    module Metrics
      # Searches for Participants in the following actions
      #  - Create an idea (Ideas)
      #  - Give support to an idea (Ideas)
      class IdeaParticipantsMetricMeasure < Decidim::MetricMeasure
        def valid?
          super && @resource.is_a?(Decidim::Component)
        end

        def calculate
          cumulative_users = []
          cumulative_users |= retrieve_ideas.pluck("decidim_coauthorships.decidim_author_id") # To avoid ambiguosity must be called this way

          quantity_users = []
          quantity_users |= retrieve_ideas(from_start: true).pluck("decidim_coauthorships.decidim_author_id") # To avoid ambiguosity must be called this way

          {
            cumulative_users: cumulative_users.uniq,
            quantity_users: quantity_users.uniq
          }
        end

        private

        def retrieve_ideas(from_start: false)
          @ideas ||= Decidim::Ideas::Idea.where(component: @resource).joins(:coauthorships)
                                         .where(
                                           decidim_coauthorships: {
                                             decidim_author_type: [
                                               "Decidim::UserBaseEntity",
                                               "Decidim::Organization",
                                               "Decidim::Meetings::Meeting"
                                             ]
                                           }
                                         )
                                         .where("decidim_ideas_ideas.published_at <= ?", end_time)
                                         .except_withdrawn

          return @ideas.where("decidim_ideas_ideas.published_at >= ?", start_time) if from_start

          @ideas
        end
      end
    end
  end
end
