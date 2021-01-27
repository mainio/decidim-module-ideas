# frozen_string_literal: true

module Decidim
  module Ideas
    module SectionControl
      # A section control object for link_ideas field type in the plans
      # component.
      class LinkIdeas < Decidim::Plans::SectionControl::Base
        cattr_accessor :plan_resources_linked

        def prepare!(plan)
          self.class.prepare_all(plan)
        end

        def finalize!(plan)
          self.class.finalize_all(plan)
        end

        def self.prepare_all(_plan)
          self.plan_resources_linked = false

          true
        end

        def self.finalize_all(plan)
          return if plan_resources_linked

          # Go through all plan sections of this type and take note about all
          # the ideas in each section.
          section_types = [:link_ideas, :link_ideas_inline]
          idea_ids = plan.contents.with_section_type(section_types).map do |sect|
            sect.body["idea_ids"]
          end.flatten.uniq

          # Store the included ideas in the plan object.
          ideas = Decidim::Ideas::Idea.where(id: idea_ids)
          plan.link_resources(ideas, "included_ideas")

          # Mark already linked so that we won't link again during the following
          # sections if there are multiple sections of the same type.
          self.plan_resources_linked = true

          true
        end
      end
    end
  end
end
