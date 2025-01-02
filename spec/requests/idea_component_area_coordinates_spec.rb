# frozen_string_literal: true

require "spec_helper"

RSpec.describe "IdeaComponentAreaCoordinates" do
  include Decidim::WardenTestHelpers

  subject { response.body }

  let(:user) { create(:user, :confirmed, :admin, organization:) }
  let(:organization) { component.organization }
  let(:component) { create(:idea_component) }
  let(:parent_scope) { create(:scope, organization:) }
  let!(:scopes) { create_list(:scope, 10, parent: parent_scope, organization:) }

  let(:decidim_admin) { Decidim::Admin::Engine.routes.url_helpers }
  let(:request_path) { decidim_admin.area_coordinates_ideas_component_setting_path(component) }

  before do
    login_as user, scope: :user

    get(
      request_path,
      params: { parent_scope_id: parent_scope.id, setting_name: "area_scope_coordinates" },
      headers: { "HOST" => organization.host }
    )
  end

  it "renders the child scopes" do
    scopes.each do |scope|
      expect(subject).to have_escaped_html(translated(scope.name))
      expect(subject).to match(/<input .*name="component\[settings\]\[area_scope_coordinates\]\[#{scope.id}\]".*>/)
    end
  end

  context "with a regular user" do
    let(:user) { create(:user, :confirmed, organization:) }

    it "redirects" do
      expect(response).to have_http_status(:found)
    end
  end

  def escaped_html(string)
    CGI.escapeHTML(string)
  end

  def have_escaped_html(string)
    include(escaped_html(string))
  end
end
