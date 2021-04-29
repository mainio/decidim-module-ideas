# frozen_string_literal: true

require "spec_helper"

describe "Admin creates idea", type: :system do
  include_context "when managing a component"

  let(:organization) { create(:organization) }
  let(:participatory_process) { create :participatory_process, :with_steps, organization: organization }
  let!(:component) do
    create(:idea_component,
           :with_creation_enabled,
           manifest: manifest,
           participatory_space: participatory_process)
  end
  let(:manifest) { Decidim.find_component_manifest("ideas") }
  let!(:scope) { create :scope, organization: organization }
  let!(:category) { create :category, participatory_space: participatory_process }
  let!(:category2) { create :category, participatory_space: participatory_process }
  let(:user) { create(:user, :admin, :confirmed, organization: organization) }

  let(:idea_title) { ::Faker::Lorem.sentence }
  let(:idea_body) { ::Faker::Lorem.paragraph }
  let!(:idea) { create(:idea, component: component) }

  before do
    visit_component_admin
  end

  describe "change idea theme" do
    it "changes idea's category" do
      find(".js-idea-id-#{idea.id}").set(true)
      click_button "Actions"
      click_button "Change theme"
      select category2.name["en"], from: :category_id
      click_button "Update"
      expect(page).to have_content("Ideas successfully updated to the theme")
      expect(Decidim::Ideas::Idea.find(idea.id).category.id).to eq(category2.id)
    end
  end

  describe "change scope" do
    it "changes idea's area scope" do
      find(".js-idea-id-#{idea.id}").set(true)
      click_button "Actions"
      click_button "Change scope"
      click_link "Global scope"
      click_link scope.name["en"]
      click_link "Select"
      find("#js-submit-scope-change-ideas").click
      expect(page).to have_content("Ideas successfully updated to the area")
      expect(Decidim::Ideas::Idea.find(idea.id).area_scope.id).to eq(scope.id)
    end
  end
end
