# frozen_string_literal: true

require "spec_helper"

describe "AdminCreatesIdea" do
  include_context "when managing a component"

  let(:organization) { create(:organization, tos_version: Time.current) }
  let!(:component) do
    create(:idea_component,
           :with_creation_enabled,
           :with_card_image_allowed,
           :with_attachments_allowed,
           :with_geocoding_enabled,
           manifest:,
           participatory_space: participatory_process)
  end
  let(:manifest) { Decidim.find_component_manifest(manifest_name) }
  let(:manifest_name) { "ideas" }
  let(:scope) { create(:scope, organization:) }
  let!(:subscope) { create(:scope, parent: scope) }
  let!(:category) { create(:category, participatory_space: participatory_process) }
  let(:user) { create(:user, :confirmed, :admin, :confirmed, organization:) }

  let(:idea_title) { Faker::Lorem.sentence }
  let(:idea_body) { Faker::Lorem.paragraph }

  before do
    component[:settings]["global"]["area_scope_parent_id"] = scope.id
    component.save!
    switch_to_host(organization.host)
    login_as user, scope: :user
    visit_component_admin
  end

  describe "create idea" do
    it "creates an idea" do
      click_on "New idea"
      fill_in :idea_title, with: idea_title
      fill_in :idea_body, with: idea_body
      select subscope.name["en"], from: :idea_area_scope_id
      select category.name["en"], from: :idea_category_id
      click_on "Create"
      expect(page).to have_content("Idea successfully created")
    end
  end

  describe "update idea" do
    let!(:idea) { create(:idea, component:) }
    let(:update_title) { Faker::Hipster.sentence }
    let(:update_body) { Faker::Hipster.paragraph }
    let!(:update_category) { create(:category, participatory_space: participatory_process) }
    let!(:update_subscope) { create(:scope, parent: scope) }

    before do
      visit current_path
      find(".action-icon--edit-idea").click
    end

    it "updates the idea" do
      fill_in :idea_title, with: update_title
      fill_in :idea_body, with: update_body
      select update_subscope.name["en"], from: :idea_area_scope_id
      select update_category.name["en"], from: :idea_category_id
      click_on "Update"
      expect(page).to have_content("Idea successfully updated")
      expect(Decidim::Ideas::Idea.find(idea.id).area_scope.id).to eq(update_subscope.id)
      expect(Decidim::Ideas::Idea.find(idea.id).category.id).to eq(update_category.id)
    end
  end
end
