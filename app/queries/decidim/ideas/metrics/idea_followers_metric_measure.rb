# frozen_string_literal: true

module Decidim
  module Ideas
    module Metrics
      # Searches for unique Users following Ideas
      class IdeaFollowersMetricMeasure < Decidim::MetricMeasure
        def valid?
          super && @resource.is_a?(Decidim::Component)
        end

        def calculate
          cumulative_users = []
          cumulative_users |= retrieve_ideas_followers.pluck(:decidim_user_id)
          cumulative_users |= retrieve_drafts_followers.pluck(:decidim_user_id)

          quantity_users = []
          quantity_users |= retrieve_ideas_followers(from_start: true).pluck(:decidim_user_id)
          quantity_users |= retrieve_drafts_followers(true).pluck(:decidim_user_id)

          {
            cumulative_users: cumulative_users.uniq,
            quantity_users: quantity_users.uniq
          }
        end

        private

        def retrieve_ideas_followers(from_start: false)
          @ideas_followers ||= Decidim::Follow.where(followable: retrieve_ideas).joins(:user)
                                              .where(decidim_follows: { created_at: ..end_time })

          return @ideas_followers.where(decidim_follows: { created_at: start_time.. }) if from_start

          @ideas_followers
        end

        def retrieve_ideas
          Decidim::Ideas::Idea.where(component: @resource).except_withdrawn
        end
      end
    end
  end
end
