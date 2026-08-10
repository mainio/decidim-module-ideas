# frozen_string_literal: true

module Decidim
  module Ideas
    module Admin
      module IdeaBulkActionsHelper
        def idea_find(id)
          Decidim::Ideas::Idea.find(id)
        end

        # Public: Generates a select field with the evaluators of the given participatory space.
        #
        # participatory_space - A participatory space instance.
        # prompt - An i18n string to show as prompt
        #
        # Returns a String.
        def bulk_evaluators_select(participatory_space, prompt)
          options_for_select = find_evaluators_for_select(participatory_space)
          select(:evaluator_role, :id, options_for_select, prompt:)
        end

        # Internal: A method to cache to queries to find the evaluators for the
        # current space.
        def find_evaluators_for_select(participatory_space)
          return @evaluators_for_select if @evaluators_for_select

          evaluator_roles = participatory_space.user_roles(:evaluator)
          evaluators = Decidim::User.where(id: evaluator_roles.pluck(:decidim_user_id)).to_a

          @evaluators_for_select = evaluator_roles.map do |role|
            evaluator = evaluators.find { |user| user.id == role.decidim_user_id }

            [evaluator.name, role.id]
          end
        end
        # rubocop:enable Rails/HelperInstanceVariable
      end
    end
  end
end
