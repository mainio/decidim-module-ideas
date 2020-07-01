# frozen_string_literal: true

module Decidim
  module Ideas
    # A class used to find ideas filtered by components and a date range
    class FilteredIdeas < Rectify::Query
      # Syntactic sugar to initialize the class and return the queried objects.
      #
      # components - An array of Decidim::Component
      # start_at - A date to filter resources created after it
      # end_at - A date to filter resources created before it.
      def self.for(components, start_at = nil, end_at = nil)
        new(components, start_at, end_at).query
      end

      # Initializes the class.
      #
      # components - An array of Decidim::Component
      # start_at - A date to filter resources created after it
      # end_at - A date to filter resources created before it.
      def initialize(components, start_at = nil, end_at = nil)
        @components = components
        @start_at = start_at
        @end_at = end_at
      end

      # Finds the Ideas scoped to an array of components and filtered
      # by a range of dates.
      def query
        ideas = Decidim::Ideas::Idea.where(component: @components)
        ideas = ideas.where("created_at >= ?", @start_at) if @start_at.present?
        ideas = ideas.where("created_at <= ?", @end_at) if @end_at.present?
        ideas
      end
    end
  end
end
