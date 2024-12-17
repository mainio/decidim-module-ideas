# frozen_string_literal: true

module Decidim
  module Ideas
    #
    # A dummy presenter to abstract out the author of an official proposal.
    #
    class OfficialAuthorPresenter < Decidim::OfficialAuthorPresenter
      def name
        I18n.t("decidim.ideas.models.idea.fields.official_idea")
      end
    end
  end
end
