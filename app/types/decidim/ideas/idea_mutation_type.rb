# frozen_string_literal: true

module Decidim
  module Ideas
    class IdeaMutationType < GraphQL::Schema::Object
      graphql_name "IdeaMutation"
      description "An idea which includes its available mutations"

      field :id, ID, null: false

      field :answer, Decidim::Ideas::IdeaType, null: true do
        description "Answer an idea"

        argument :state, String, description: "The answer status in which the idea is in. Can be one of 'accepted', 'rejected' or 'evaluating'", required: true
        argument :answer_content, GraphQL::Types::JSON, description: "The answer feedback for the status for this idea", required: false
      end

      def answer(state:, answer_content: nil)
        enforce_permission_to :create, :idea_answer, idea: object

        params = {
          "idea_answer" => {
            "internal_state" => state,
            "answer" => answer_content
          }
        }
        form = Decidim::Ideas::Admin::IdeaAnswerForm.from_params(
          params
        ).with_context(
          current_organization: current_organization,
          current_component: object.component,
          current_user: current_user
        )

        idea = object
        Decidim::Ideas::Admin::AnswerIdea.call(form, idea) do
          on(:ok) do
            return idea
          end
          on(:invalid) do
            return GraphQL::ExecutionError.new(
              form.errors.full_messages.join(', ')
            )
          end
        end

        GraphQL::ExecutionError.new(
          I18n.t("decidim.ideas.admin.ideas.answer.invalid")
        )
      end

      private

      def current_organization
        context[:current_organization]
      end

      def current_user
        context[:current_user]
      end

      def enforce_permission_to(action, subject, extra_context = {})
        raise Decidim::Ideas::ActionForbidden unless allowed_to?(action, subject, extra_context)
      end

      def allowed_to?(action, subject, extra_context = {}, user = current_user)
        scope ||= :admin
        permission_action = Decidim::PermissionAction.new(scope: scope, action: action, subject: subject)

        permission_class_chain.inject(permission_action) do |current_permission_action, permission_class|
          permission_class.new(
            user,
            current_permission_action,
            permissions_context.merge(extra_context)
          ).permissions
        end.allowed?
      rescue Decidim::PermissionAction::PermissionNotSetError
        false
      end

      def permission_class_chain
        [
          object.component.manifest.permissions_class,
          object.participatory_space.manifest.permissions_class,
          ::Decidim::Admin::Permissions,
          ::Decidim::Permissions
        ]
      end

      def permissions_context
        {
          current_settings: object.component.current_settings,
          component_settings: object.component.settings,
          current_organization: object.organization,
          current_component: object.component
        }
      end

      class ::Decidim::Ideas::ActionForbidden < StandardError
      end
    end
  end
end
