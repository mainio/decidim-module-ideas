# frozen_string_literal: true

require "spec_helper"

describe "AdminCreatesIdea" do
  include_context "when managing a component"

  let(:organization) { create(:organization, tos_version: Time.current) }
  let(:participatory_process) { create(:participatory_process, :with_steps, organization:) }
  let!(:component) do
    create(:idea_component,
           :with_creation_enabled,
           manifest:,
           participatory_space: participatory_process)
  end
  let(:manifest) { Decidim.find_component_manifest("ideas") }
  let!(:scope) { create(:scope, organization:) }
  let!(:category) { create(:category, participatory_space: participatory_process) }
  let!(:second_category) { create(:category, participatory_space: participatory_process) }
  let(:user) { create(:user, :admin, :confirmed, organization:) }

  let(:idea_title) { Faker::Lorem.sentence }
  let(:idea_body) { Faker::Lorem.paragraph }
  let!(:idea) { create(:idea, component:) }

  before do
    visit_component_admin
  end

  describe "change idea theme" do
    it "changes idea's category" do
      find(".js-idea-id-#{idea.id}").set(true)
      click_on "Actions"
      click_on "Change theme"
      select second_category.name["en"], from: :category_id
      click_on "Update"
      expect(page).to have_content("Ideas successfully updated to the theme")
      expect(Decidim::Ideas::Idea.find(idea.id).category.id).to eq(second_category.id)
    end
  end

  describe "change scope" do
    it "changes idea's area scope" do
      find(".js-idea-id-#{idea.id}").set(true)
      click_on "Actions"
      click_on "Change scope"

      select scope.name["en"], from: "area_scope_id"

      find_by_id("js-submit-scope-change-ideas").click
      expect(page).to have_content("Ideas successfully updated to the area")
      expect(Decidim::Ideas::Idea.find(idea.id).area_scope.id).to eq(scope.id)
    end
  end

  describe "moderations" do
    let(:moderation) { create(:moderation, reportable: idea, report_count: 1) }
    let!(:report) { create(:report, moderation:) }

    before do
      click_on "Moderations"
    end

    it "unreports" do
      find(".action-icon--unreport").click
      expect(page).to have_content("Resource successfully unreported")
    end

    it "hides" do
      find(".action-icon--hide").click
      expect(page).to have_content("Resource successfully hidden")
      expect(Decidim::Ideas::Idea.find(idea.id).hidden?).to be(true)
    end
  end
end
