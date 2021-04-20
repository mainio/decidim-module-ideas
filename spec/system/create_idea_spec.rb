# frozen_string_literal: true

require "spec_helper"

describe "User creates idea", type: :system do
  include_context "with a component"

  let(:organization) { create :organization, *organization_traits, available_locales: [:en] }
  let(:participatory_process) { create :participatory_process, :with_steps, organization: organization }
  let(:manifest_name) { "ideas" }
  let(:manifest) { Decidim.find_component_manifest(manifest_name) }
  let!(:user) { create :user, :confirmed, organization: organization }
  let!(:component) do
    create(:idea_component,
           :with_creation_enabled,
           manifest: manifest,
           participatory_space: participatory_process)
  end
  let(:organization_traits) { [] }
  let(:scope) { create :scope, organization: organization }
  let!(:subscope) { create :scope, parent: scope }
  let!(:category) { create :category, participatory_space: participatory_process }

  let(:idea_title) { ::Faker::Lorem.paragraph }
  let(:idea_body) { ::Faker::Lorem.paragraph }

  def visit_component
    page.visit main_component_path(component)
  end

  before do
    component[:settings]["global"]["area_scope_parent_id"] = scope.id
    component.save!
    login_as user, scope: :user
    visit_component
  end

  describe "idea creation process" do
    it "creates a new idea with a category and scope" do
      click_link "New idea"
      fill_in :idea_title, with: idea_title
      find(:css, "#idea_terms_agreed").set(true)
      fill_in :idea_body, with: idea_body
      fill_category_and_scope
      click_button "Continue"
      click_button "Publish"
      expect(page).to have_content("Idea successfully published")
    end
  end

  def fill_category_and_scope
    select category.name["en"], from: :idea_category_id
    select subscope.name["en"], from: :idea_area_scope_id
  end
end
