# frozen_string_literal: true

module Decidim
  module Ideas
    class IdeasController < Decidim::Ideas::ApplicationController
      helper Decidim::WidgetUrlsHelper
      helper IdeaWizardHelper
      helper Decidim::Ideas::IdeasFormHelper

      include Decidim::ApplicationHelper
      include FormFactory
      include FilterResource
      include Decidim::Ideas::Orderable
      include Paginable

      helper_method :idea_form_builder, :idea_presenter, :form_presenter, :trigger_feedback?

      before_action :authenticate_user!, only: [:create, :complete]
      before_action :ensure_creation_enabled, only: [:new]
      before_action :ensure_is_draft, only: [:compare, :complete, :preview, :publish, :edit_draft, :update_draft, :destroy_draft]
      before_action :set_idea, only: [:show, :edit, :update, :withdraw]
      before_action :edit_form, only: [:edit_draft, :edit]

      def index
        @ideas = search
                 .results
                 .published
                 .not_hidden
                 .includes(:amendable, :category, :component, :area_scope)

        @voted_ideas = begin
          if current_user
            IdeaVote.where(
              author: current_user,
              idea: @ideas.pluck(:id)
            ).pluck(:decidim_idea_id)
          else
            []
          end
        end
        @ideas = paginate(@ideas)
        @ideas = reorder(@ideas)
      end

      def show
        raise ActionController::RoutingError, "Not Found" if @idea.blank? || !can_show_idea?

        @report_form = form(Decidim::ReportForm).from_params(reason: "spam")
      end

      def new
        if idea_draft.present?
          redirect_to edit_draft_idea_path(
            idea_draft,
            component_id: idea_draft.component.id,
            question_slug: idea_draft.component.participatory_space.slug
          )
        else
          @idea ||= Idea.new(component: current_component)
          @form = form_idea_model
          @form.image = form_image_attachment_new
          @form.attachment = form_attachment_new
        end
      end

      def create
        enforce_permission_to :create, :idea
        @form = form(IdeaForm).from_params(idea_creation_params)

        # In case of an error
        @idea ||= Idea.new(component: current_component)

        show_preview = params[:save_type] != "save"

        CreateIdea.call(@form, current_user) do
          on(:ok) do |idea|
            flash[:notice] = I18n.t("ideas.create.success", scope: "decidim")

            if show_preview
              redirect_to Decidim::ResourceLocatorPresenter.new(idea).path + "/preview"
            else
              redirect_to Decidim::ResourceLocatorPresenter.new(idea).path + "/edit_draft"
            end
          end

          on(:invalid) do
            flash.now[:alert] = I18n.t("ideas.create.error", scope: "decidim")

            @form.image = form_image_attachment_new
            @form.attachment = form_attachment_new

            render :new
          end
        end
      end

      def preview; end

      def publish
        PublishIdea.call(@idea, current_user) do
          on(:ok) do
            flash[:notice] = I18n.t("ideas.publish.success", scope: "decidim")
            session["decidim-ideas.published"] = true
            redirect_to idea_path(@idea)
          end

          on(:invalid) do
            flash.now[:alert] = I18n.t("ideas.publish.error", scope: "decidim")
            render :edit_draft
          end
        end
      end

      def edit_draft
        enforce_permission_to :edit, :idea, idea: @idea
      end

      def update_draft
        enforce_permission_to :edit, :idea, idea: @idea
        show_preview = params[:save_type] != "save"

        @form = form_idea_params
        UpdateIdea.call(@form, current_user, @idea) do
          on(:ok) do |idea|
            flash[:notice] = I18n.t("ideas.update_draft.success", scope: "decidim")
            if show_preview
              redirect_to Decidim::ResourceLocatorPresenter.new(idea).path + "/preview"
            else
              redirect_to Decidim::ResourceLocatorPresenter.new(idea).path + "/edit_draft"
            end
          end

          on(:invalid) do
            flash.now[:alert] = I18n.t("ideas.update_draft.error", scope: "decidim")
            render :edit_draft
          end
        end
      end

      def destroy_draft
        enforce_permission_to :edit, :idea, idea: @idea

        DestroyIdea.call(@idea, current_user) do
          on(:ok) do
            flash[:notice] = I18n.t("ideas.destroy_draft.success", scope: "decidim")
            redirect_to new_idea_path
          end

          on(:invalid) do
            flash.now[:alert] = I18n.t("ideas.destroy_draft.error", scope: "decidim")
            render :edit_draft
          end
        end
      end

      def edit
        enforce_permission_to :edit, :idea, idea: @idea
      end

      def update
        enforce_permission_to :edit, :idea, idea: @idea

        @form = form_idea_params
        AmendIdea.call(@form, current_user, @idea) do
          on(:ok) do |idea|
            flash[:notice] = I18n.t("ideas.update.success", scope: "decidim")
            redirect_to Decidim::ResourceLocatorPresenter.new(idea).path
          end

          on(:invalid) do
            flash.now[:alert] = I18n.t("ideas.update.error", scope: "decidim")
            render :edit
          end
        end
      end

      def withdraw
        enforce_permission_to :withdraw, :idea, idea: @idea

        WithdrawIdea.call(@idea, current_user) do
          on(:ok) do
            flash[:notice] = I18n.t("ideas.update.success", scope: "decidim")
            redirect_to Decidim::ResourceLocatorPresenter.new(@idea).path
          end
          on(:has_supports) do
            flash[:alert] = I18n.t("ideas.withdraw.errors.has_supports", scope: "decidim")
            redirect_to Decidim::ResourceLocatorPresenter.new(@idea).path
          end
        end
      end

      private

      def trigger_feedback?
        @trigger_feedback ||= session.delete("decidim-ideas.published")
      end

      def layout
        case action_name
        when "new", "create", "edit", "edit_draft", "update", "preview"
          "decidim/ideas/participatory_space_plain"
        else
          super
        end
      end

      def search_klass
        IdeaSearch
      end

      def default_filter_params
        {
          search_text: "",
          origin: default_filter_origin_params,
          activity: "all",
          area_scope_id: "",
          category_id: "",
          state: %w(accepted rejected evaluating not_answered),
          related_to: "",
          type: "ideas"
        }
      end

      def default_filter_origin_params
        filter_origin_params = %w(citizens)
        filter_origin_params << "user_group" if current_organization.user_groups_enabled?
        filter_origin_params
      end

      def idea_draft
        return nil unless user_signed_in?

        Idea.from_all_author_identities(current_user).not_hidden.only_amendables
            .where(component: current_component).find_by(published_at: nil)
      end

      def ensure_is_draft
        @idea = Idea.not_hidden.where(component: current_component).find(params[:id])
        redirect_to Decidim::ResourceLocatorPresenter.new(@idea).path unless @idea.draft?
      end

      def ensure_creation_enabled
        redirect_to ideas_path unless current_settings&.creation_enabled?
      end

      def set_idea
        @idea = Idea.published.not_hidden.where(component: current_component).find_by(id: params[:id])
      end

      # Returns true if the idea is NOT an emendation or the user IS an admin.
      # Returns false if the idea is not found or the idea IS an emendation
      # and is NOT visible to the user based on the component's amendments settings.
      def can_show_idea?
        return true if @idea&.amendable? || current_user&.admin?

        Idea.only_visible_emendations_for(current_user, current_component).published.include?(@idea)
      end

      def idea_form_builder
        return Decidim::Ideas::FormBuilderDisabled unless user_signed_in?

        Decidim::Ideas::FormBuilder
      end

      def idea_presenter
        @idea_presenter ||= present(@idea)
      end

      def form_idea_params
        form(IdeaForm).from_params(params)
      end

      def form_idea_model
        form(IdeaForm).from_model(@idea)
      end

      def form_presenter
        @form_presenter ||= present(@form, presenter_class: Decidim::Ideas::IdeaPresenter)
      end

      def form_image_attachment_new
        form(Decidim::Ideas::ImageAttachmentForm).from_params({})
      end

      def form_attachment_new
        form(Decidim::Ideas::AttachmentForm).from_params({})
      end

      def edit_form
        form_image_model = form(ImageAttachmentForm).from_model(@idea.image)
        form_attachment_model = form(AttachmentForm).from_model(@idea.actual_attachments.first)
        @form = form_idea_model
        @form.image = form_image_model
        @form.attachment = form_attachment_model
        @form
      end

      def idea_creation_params
        params[:idea]
      end
    end
  end
end
