# frozen_string_literal: true

require "spec_helper"

describe Decidim::Admin::IdeasComponentSettingsController do
  routes { Decidim::Admin::Engine.routes }

  let(:user) { create(:user, :confirmed, :admin, organization:) }
  let(:organization) { component.organization }
  let(:component) { create(:idea_component) }
  let(:parent_scope) { create(:scope, organization:) }

  before do
    request.env["decidim.current_organization"] = organization
    sign_in user
  end

  describe "GET area_coordinates" do
    it "returns the correct coordinates" do
      get :area_coordinates, params: { id: component.id, parent_scope_id: parent_scope.id, setting_name: "area_scope_coordinates" }
      expect(response).to have_http_status(:ok)
      expect(response).to render_template("decidim/ideas/admin/shared/_area_scope_coordinates")
    end

    context "when the parent scope is not defined" do
      it "shows a 404" do
        expect do
          get :area_coordinates, params: { id: component.id, parent_scope_id: 0, setting_name: "area_scope_coordinates" }
        end.to raise_error(ActionController::RoutingError)
      end
    end

    context "when the settings name is not found" do
      it "shows a 404" do
        expect do
          get :area_coordinates, params: { id: component.id, parent_scope_id: parent_scope.id, setting_name: "foobar" }
        end.to raise_error(ActionController::RoutingError)
      end
    end

    context "when the settings type is not the expected one" do
      it "shows a 404" do
        expect do
          get :area_coordinates, params: { id: component.id, parent_scope_id: parent_scope.id, setting_name: "area_scope_parent_id" }
        end.to raise_error(ActionController::RoutingError)
      end
    end
  end
end
