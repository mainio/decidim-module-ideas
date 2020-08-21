# frozen_string_literal: true

module Decidim
  module Ideas
    module Admin
      # A form object to be used when admin users want to answer a idea.
      class IdeaAnswerForm < Decidim::Form
        include TranslatableAttributes
        mimic :idea_answer

        translatable_attribute :answer, String
        attribute :internal_state, String

        validates :internal_state, presence: true, inclusion: { in: %w(accepted rejected evaluating) }
        validates :answer, translatable_presence: true, if: ->(form) { form.state == "rejected" }

        alias state internal_state

        def publish_answer?
          current_component.current_settings.publish_answers_immediately?
        end
      end
    end
  end
end
