# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module Ideas
    # Common logic to ordering resources
    module Orderable
      extend ActiveSupport::Concern

      included do
        include Decidim::Orderable

        private

        # Available orders based on enabled settings
        def available_orders
          @available_orders ||= begin
            available_orders = %w(recent oldest)
            available_orders << "most_voted" if most_voted_order_available?
            available_orders << "most_commented" if component_settings.comments_enabled?
            available_orders << "most_followed"
            available_orders
          end
        end

        def default_order
          if order_by_votes?
            detect_order("most_voted")
          else
            "recent"
          end
        end

        def most_voted_order_available?
          current_settings.votes_enabled? && !current_settings.votes_hidden?
        end

        def order_by_votes?
          most_voted_order_available? && current_settings.votes_blocked?
        end

        def reorder(ideas)
          case order
          when "most_commented"
            ideas.left_joins(:comments).group(:id).order(Arel.sql("COUNT(decidim_comments_comments.id) DESC"))
          when "most_followed"
            ideas.left_joins(:follows).group(:id).order(Arel.sql("COUNT(decidim_follows.id) DESC"))
          when "most_voted"
            ideas.order(idea_votes_count: :desc)
          when "recent"
            ideas.order(published_at: :desc)
          when "oldest"
            ideas.order(:published_at)
          when "with_more_authors"
            ideas.order(coauthorships_count: :desc)
          end
        end
      end
    end
  end
end
