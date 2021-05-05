# frozen_string_literal: true

module Decidim
  module Ideas
    module Admin
      # This class contains helpers needed to get rankings for a given idea
      # ordered by some given criteria.
      #
      module IdeaRankingsHelper
        # Public: Gets the ranking for a given idea, ordered by some given
        # criteria. Idea is sorted amongst its own siblings.
        #
        # Returns a Hash with two keys:
        #   :ranking - an Integer representing the ranking for the given idea.
        #     Ranking starts with 1.
        #   :total - an Integer representing the total number of ranked ideas.
        #
        # Example:
        #   ranking_for(idea, idea_votes_count: :desc)
        def ranking_for(idea, order = {})
          siblings = Decidim::Ideas::Idea.where(component: idea.component)
          ranked = siblings.order([order, id: :asc])
          ranked_ids = ranked.pluck(:id)

          { ranking: ranked_ids.index(idea.id) + 1, total: ranked_ids.count }
        end
      end
    end
  end
end
