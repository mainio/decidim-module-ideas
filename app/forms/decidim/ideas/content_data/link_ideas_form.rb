# frozen_string_literal: true

module Decidim
  module Ideas
    module ContentData
      # A form object for the text field type.
      class LinkIdeasForm < Decidim::Plans::ContentData::BaseForm
        mimic :plan_link_ideas

        attribute :idea_ids, Array[Integer]

        validates :idea_ids, presence: true, if: ->(form) { form.mandatory }

        def map_model(model)
          super
          return unless model.body

          ids = model.body["idea_ids"]
          return unless ids.is_a?(Array)

          self.idea_ids = ids
        end

        def body
          { idea_ids: idea_ids }
        end

        def body=(data)
          return unless data.is_a?(Hash)

          self.idea_ids = data["idea_ids"] || data[:idea_ids]
        end

        def ideas
          Decidim::Ideas::Idea.where(id: idea_ids)
        end
      end
    end
  end
end
