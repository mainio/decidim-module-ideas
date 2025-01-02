# frozen_string_literal: true

module Decidim
  module Ideas
    module Admin
      module IdeaBulkActionsHelper
        def idea_find(id)
          Decidim::Ideas::Idea.find(id)
        end

        # Public: Generates a select field with the valuators of the given participatory space.
        #
        # participatory_space - A participatory space instance.
        # prompt - An i18n string to show as prompt
        #
        # Returns a String.
        def bulk_valuators_select(participatory_space, prompt)
          options_for_select = find_valuators_for_select(participatory_space)
          select(:valuator_role, :id, options_for_select, prompt:)
        end

        # Internal: A method to cache to queries to find the valuators for the
        # current space.
        # rubocop:disable Rails/HelperInstanceVariable
        def find_valuators_for_select(participatory_space)
          return @valuators_for_select if @valuators_for_select

          valuator_roles = participatory_space.user_roles(:valuator)
          valuators = Decidim::User.where(id: valuator_roles.pluck(:decidim_user_id)).to_a

          @valuators_for_select = valuator_roles.map do |role|
            valuator = valuators.find { |user| user.id == role.decidim_user_id }

            [valuator.name, role.id]
          end
        end
        # rubocop:enable Rails/HelperInstanceVariable
      end
    end
  end
end
