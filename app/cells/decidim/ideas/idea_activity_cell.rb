# frozen_string_literal: true

module Decidim
  module Ideas
    # A cell to display when a idea has been published.
    class IdeaActivityCell < ActivityCell
      def title
        action == "update" ? I18n.t("decidim.ideas.last_activity.idea_updated_html") : I18n.t("decidim.ideas.last_activity.new_idea_at_html")
      end

      def resource_link_text
        decidim_html_escape(presenter.title)
      end

      def description
        strip_tags(presenter.body(links: true))
      end

      def presenter
        @presenter ||= Decidim::Ideas::IdeaPresenter.new(resource)
      end
    end
  end
end
