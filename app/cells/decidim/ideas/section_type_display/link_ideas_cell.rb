# frozen_string_literal: true

module Decidim
  module Ideas
    module SectionTypeDisplay
      class LinkIdeasCell < Decidim::Plans::SectionDisplayCell
        include Decidim::CardHelper

        def show
          return if ideas.blank?

          render
        end

        private

        def ideas
          return [] unless model.body["idea_ids"]

          @ideas ||= model.body["idea_ids"].map do |id|
            Decidim::Ideas::Idea.find_by(id: id)
          end.compact
        end
      end
    end
  end
end
