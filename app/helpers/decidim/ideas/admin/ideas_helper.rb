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
            present(identity)
          end
        end

        def idea_complete_state(idea)
          state = humanize_idea_state(idea.state)
          state += " (#{humanize_idea_state(idea.internal_state)})" if idea.answered? && !idea.published_state?
          state.html_safe
        end

        def ideas_admin_filter_tree
          {
            t("ideas.filters.type", scope: "decidim.ideas") => {
              link_to(t("ideas", scope: "decidim.ideas.application_helper.filter_type_values"), q: ransak_params_for_query(is_emendation_true: "0"),
                                                                                                per_page: per_page) => nil,
              link_to(t("amendments", scope: "decidim.ideas.application_helper.filter_type_values"), q: ransak_params_for_query(is_emendation_true: "1"),
                                                                                                     per_page: per_page) => nil
            },
            t("models.idea.fields.state", scope: "decidim.ideas") =>
              Decidim::Ideas::Idea::POSSIBLE_STATES.each_with_object({}) do |state, hash|
                if state == "not_answered"
                  hash[link_to((humanize_idea_state state), q: ransak_params_for_query(state_null: 1), per_page: per_page)] = nil
                else
                  hash[link_to((humanize_idea_state state), q: ransak_params_for_query(state_eq: state), per_page: per_page)] = nil
                end
              end,
            t("models.idea.fields.category", scope: "decidim.ideas") => admin_filter_categories_tree(categories.first_class),
            t("ideas.filters.scope", scope: "decidim.ideas") => admin_filter_scopes_tree(current_component.organization.id)
          }
        end

        def ideas_admin_search_hidden_params
          return unless params[:q]

          tags = ""
          tags += hidden_field_tag "per_page", params[:per_page] if params[:per_page]
          tags += hidden_field_tag "q[is_emendation_true]", params[:q][:is_emendation_true] if params[:q][:is_emendation_true]
          tags += hidden_field_tag "q[state_eq]", params[:q][:state_eq] if params[:q][:state_eq]
          tags += hidden_field_tag "q[category_id_eq]", params[:q][:category_id_eq] if params[:q][:category_id_eq]
          tags += hidden_field_tag "q[scope_id_eq]", params[:q][:scope_id_eq] if params[:q][:scope_id_eq]
          tags.html_safe
        end

        def ideas_admin_filter_applied_filters
          html = []
          if params[:q][:is_emendation_true].present?
            html << content_tag(:span, class: "label secondary") do
              tag = "#{t("filters.type", scope: "decidim.ideas.ideas")}: "
              tag += if params[:q][:is_emendation_true].to_s == "1"
                       t("amendments", scope: "decidim.ideas.application_helper.filter_type_values")
                     else
                       t("ideas", scope: "decidim.ideas.application_helper.filter_type_values")
                     end
              tag += icon_link_to("circle-x", url_for(q: ransak_params_for_query_without(:is_emendation_true), per_page: per_page), t("decidim.admin.actions.cancel"),
                                  class: "action-icon--remove")
              tag.html_safe
            end
          end
          if params[:q][:state_null]
            html << content_tag(:span, class: "label secondary") do
              tag = "#{t("models.idea.fields.state", scope: "decidim.ideas")}: "
              tag += humanize_idea_state "not_answered"
              tag += icon_link_to("circle-x", url_for(q: ransak_params_for_query_without(:state_null), per_page: per_page), t("decidim.admin.actions.cancel"),
                                  class: "action-icon--remove")
              tag.html_safe
            end
          end
          if params[:q][:state_eq]
            html << content_tag(:span, class: "label secondary") do
              tag = "#{t("models.idea.fields.state", scope: "decidim.ideas")}: "
              tag += humanize_idea_state params[:q][:state_eq]
              tag += icon_link_to("circle-x", url_for(q: ransak_params_for_query_without(:state_eq), per_page: per_page), t("decidim.admin.actions.cancel"),
                                  class: "action-icon--remove")
              tag.html_safe
            end
          end
          if params[:q][:category_id_eq]
            html << content_tag(:span, class: "label secondary") do
              tag = "#{t("models.idea.fields.category", scope: "decidim.ideas")}: "
              tag += translated_attribute categories.find(params[:q][:category_id_eq]).name
              tag += icon_link_to("circle-x", url_for(q: ransak_params_for_query_without(:category_id_eq), per_page: per_page), t("decidim.admin.actions.cancel"),
                                  class: "action-icon--remove")
              tag.html_safe
            end
          end
          if params[:q][:scope_id_eq]
            html << content_tag(:span, class: "label secondary") do
              tag = "#{t("models.idea.fields.scope", scope: "decidim.ideas")}: "
              tag += translated_attribute Decidim::Scope.where(decidim_organization_id: current_component.organization.id).find(params[:q][:scope_id_eq]).name
              tag += icon_link_to("circle-x", url_for(q: ransak_params_for_query_without(:scope_id_eq), per_page: per_page), t("decidim.admin.actions.cancel"),
                                  class: "action-icon--remove")
              tag.html_safe
            end
          end
          html.join(" ").html_safe
        end

        def icon_with_link_to_idea(idea)
          icon, tooltip = if allowed_to?(:create, :idea_answer, idea: idea) && !idea.emendation?
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
