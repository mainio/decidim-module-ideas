# frozen_string_literal: true

module Decidim
  module Ideas
    # A service to encapsualte all the logic when searching and filtering
    # ideas in a participatory process.
    class IdeaSearch < ResourceSearch
      attr_reader :activity

      def build(params)
        @activity = params.delete(:activity)

        if activity && user
          case activity
          when "my_ideas"
            add_scope(:from_author, user)
          when "my_favorites"
            add_scope(:user_favorites, user)
          end
        end

        super
      end
    end
  end
end
