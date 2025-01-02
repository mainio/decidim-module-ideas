# frozen_string_literal: true

module Decidim
  module Ideas
    # Simple helpers to handle markup variations for idea wizard partials
    module IdeaWizardHelper
      # Renders a user_group select field in a form.
      # form - FormBuilder object
      # name - attribute user_group_id
      #
      # Returns nothing.
      def user_group_select_field(form, name)
        selected = @form.user_group_id.presence # rubocop:disable Rails/HelperInstanceVariable
        user_groups = Decidim::UserGroups::ManageableUserGroups.for(current_user).verified
        form.select(
          name,
          user_groups.map { |g| [g.name, g.id] },
          selected:,
          include_blank: current_user.name
        )
      end

      private

      def type_of
        :ideas
      end
    end
  end
end
