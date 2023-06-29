# frozen_string_literal: true

require "spec_helper"

describe Decidim::Ideas::Admin::IdeaAnswersController, type: :controller do
  routes { Decidim::Ideas::AdminEngine.routes }

  let(:user) { create(:user, :confirmed, :admin, organization: participatory_space.organization) }
  let(:participatory_space) { create(:participatory_process, organization: create(:organization, tos_version: Time.current)) }
  let(:component) { create(:idea_component, participatory_space: participatory_space) }
  let(:idea) { create(:idea, component: component) }

  before do
    request.env["decidim.current_organization"] = participatory_space.organization
    request.env["decidim.current_participatory_space"] = participatory_space
    request.env["decidim.current_component"] = component
    sign_in user
  end

  describe "POST update" do
    let(:params) do
      {
        component_id: component.id,
        participatory_process_slug: participatory_space.slug,
        id: idea.id,
        idea_id: idea.id,
        idea_answer: answer_params
      }
    end
    let(:answer_params) { { internal_state: "accepted", answer: { en: "Good idea!" } } }

    it "redirects to the ideas path" do
      post :update, params: params
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to("/processes/#{participatory_space.slug}/f/#{component.id}/ideas")
    end

    context "when the answer is not provided and status is rejected" do
      let(:answer_params) { { internal_state: "rejected", answer: { en: "" } } }

      it "renders the edit view" do
        post :update, params: params
        expect(response).to have_http_status(:ok)
        expect(response).to render_template("decidim/ideas/admin/ideas/show")
      end
    end
  end
end
