# frozen_string_literal: true

require "spec_helper"

describe "User edits idea", type: :system do
  include_context "with a component"

  let(:organization) { create :organization }
  let(:participatory_process) { create :participatory_process, :with_steps, organization: organization }
  let(:manifest) { Decidim.find_component_manifest("ideas") }
  let!(:user) { create :user, :confirmed, organization: organization }
  let!(:component) { create(:idea_component, manifest: manifest, participatory_space: participatory_process) }
  let(:scope) { create :scope, organization: organization }
  let!(:subscope) { create :scope, parent: scope }
  let!(:category) { create :category, participatory_space: participatory_process }
  let!(:comment) { create(:comment, commentable: idea) }

  let!(:idea) { create(:idea, component: component, title: idea_title, body: idea_body, area_scope_parent: scope, category: category) }
  let(:idea_title) { ::Faker::Lorem.paragraph }
  let(:idea_body) { ::Faker::Lorem.paragraph }

  before do
    component[:settings]["global"]["area_scope_parent_id"] = scope.id
    settings = component.settings
    settings.area_scope_coordinates = { subscope.id.to_s => "60.1699,24.9384" }
    component.settings = settings
    component.save!
    login_as user, scope: :user
    visit_component
  end

  describe "show" do
    it "shows the idea" do
      click_link idea.title
      expect(page).to have_content(idea.title)
      expect(page).to have_content(idea.body)
      expect(page).to have_content(subscope.name["en"])
      expect(page).to have_content(category.name["en"])
      expect(page).to have_content(comment.body["en"])
    end
  end
end
