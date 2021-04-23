# frozen_string_literal: true

require "spec_helper"

describe "Admin manages idea component", type: :system do
  include_context "when managing a component"

  let(:organization) { create(:organization) }
  let!(:component) do
    create(:idea_component,
           :with_creation_enabled,
           :with_card_image_allowed,
           :with_attachments_allowed,
           :with_geocoding_enabled,
           manifest: manifest,
           participatory_space: participatory_process)
  end
  let(:manifest) { Decidim.find_component_manifest(manifest_name) }
  let(:manifest_name) { "ideas" }
  let(:scope) { create :scope, organization: organization }
  let!(:subscope) { create :scope, parent: scope }
  let!(:category) { create :category, participatory_space: participatory_process }
  let(:user) { create(:user, :admin, :confirmed, organization: organization) }

  def components_path(component)
    Decidim::EngineRouter.admin_proxy(component.participatory_space).components_path(component.id)
  end

  before do
    component[:settings]["global"]["area_scope_parent_id"] = scope.id
    component.save!
    switch_to_host(organization.host)
    login_as user, scope: :user
    visit components_path(component)
  end

  describe "configure" do
    before do
      # visit current_path
      find(".icon--cog").click
    end

    it "updates component's settings" do
      click_button "Update"
      expect(page).to have_content("The component was updated successfully")
    end
  end
end
