# frozen_string_literal: true

module Decidim
  module Ideas
    module AdminLog
      # This class holds the logic to present a `Decidim::Ideas::Idea`
      # for the `AdminLog` log.
      #
      # Usage should be automatic and you shouldn't need to call this class
      # directly, but here's an example:
      #
      #    action_log = Decidim::ActionLog.last
      #    view_helpers # => this comes from the views
      #    IdeaPresenter.new(action_log, view_helpers).present
      class IdeaPresenter < Decidim::Log::BasePresenter
        private

        def resource_presenter
          @resource_presenter ||= Decidim::Ideas::Log::ResourcePresenter.new(action_log.resource, h, action_log.extra["resource"])
        end

        def diff_fields_mapping
          {
            title: "Decidim::Ideas::AdminLog::ValueTypes::IdeaTitleBodyPresenter",
            body: "Decidim::Ideas::AdminLog::ValueTypes::IdeaTitleBodyPresenter",
            state: "Decidim::Ideas::AdminLog::ValueTypes::IdeaStatePresenter",
            answered_at: :date,
            answer: :i18n
          }
        end

        def action_string
          case action
          when "answer", "create", "update", "publish_answer"
            "decidim.ideas.admin_log.idea.#{action}"
          else
            super
          end
        end

        def i18n_labels_scope
          "activemodel.attributes.idea"
        end

        def has_diff?
          %w(answer update create).include?(action.to_s) && action_log.version.present?
        end
      end
    end
  end
end
