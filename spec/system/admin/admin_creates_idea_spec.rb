# frozen_string_literal: true

require "spec_helper"

describe "Admin creates idea", type: :system do
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

  let(:idea_title) { ::Faker::Lorem.sentence }
  let(:idea_body) { ::Faker::Lorem.paragraph }

  before do
    component[:settings]["global"]["area_scope_parent_id"] = scope.id
    component.save!
    switch_to_host(organization.host)
    login_as user, scope: :user
    visit_component_admin
  end

  describe "create idea" do
    it "creates an idea" do
      click_link "New idea"
      fill_in :idea_title, with: idea_title
      fill_in :idea_body, with: idea_body
      select subscope.name["en"], from: :idea_area_scope_id
      select category.name["en"], from: :idea_category_id
      click_button "Create"
      expect(page).to have_content("Idea successfully created")
    end
  end
end
