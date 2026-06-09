# frozen_string_literal: true

module Decidim
  module Ideas
    module Admin
      # This class contains helpers needed to format Meetings
      # in order to use them in select forms for Ideas.
      #
      module IdeasHelper
        include Decidim::UserGroupHelper

        def coauthor_presenters_for(idea)
          idea.authors.map do |identity|
            if identity.is_a?(Decidim::Organization)
              Decidim::Ideas::OfficialAuthorPresenter.new
            else
              present(identity)
            end
          end
        end

        def idea_complete_state(idea)
          state = humanize_idea_state(idea.state)
          state += " (#{humanize_idea_state(idea.internal_state)})" if idea.answered? && !idea.published_state?
          state.html_safe
        end

        def icon_with_link_to_idea(idea)
          icon, tooltip = if allowed_to?(:create, :idea_answer, idea:) && !idea.emendation?
                            [
                              "question-answer-line",
                              t(:answer_idea, scope: "decidim.ideas.actions")
                            ]
                          else
                            [
                              "information-line",
                              t(:show, scope: "decidim.ideas.actions")
                            ]
                          end
          icon_link_to(icon, idea_path(idea), tooltip, class: "icon--small action-icon--show-idea")
        end
      end
    end
  end
end
