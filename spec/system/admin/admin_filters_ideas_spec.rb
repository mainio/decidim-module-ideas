# frozen_string_literal: true

require "spec_helper"

describe "AdminFiltersIdeas" do
  include_context "when managing a component"

  let(:organization) { create(:organization, tos_version: Time.current) }
  let(:participatory_process) { create(:participatory_process, :with_steps, organization:) }
  let!(:component) { create(:idea_component, :with_creation_enabled, manifest:, participatory_space: participatory_process) }
  let(:manifest) { Decidim.find_component_manifest("ideas") }
  let(:user) { create(:user, :confirmed, :admin, :confirmed, organization:) }
  let!(:parent_area_scope) { create(:scope, organization:) }

  let(:idea_title) { Faker::Lorem.sentence }
  let(:second_idea_title) { Faker::Hipster.sentence }
  let(:third_idea_title) { "Palasin juuri uudesta koulustani, sain tänään tietää" }
  let(:fourth_idea_title) { "Mieleni minun tekevi, aivoni ajattelevi lähteäni laulamahan" }
  let(:fifth_idea_title) { "Jukolan talo, eteläisessä Hämeessä, seisoo erään mäen pohjoisella rinteellä" }
  let(:titles) { [idea_title, second_idea_title, third_idea_title, fourth_idea_title, fifth_idea_title] }

  before do
    component[:settings]["global"]["area_scope_parent_id"] = parent_area_scope.id
    component.save!
    visit_component_admin
  end

  # rubocop:disable RSpec/NoExpectationExample

  describe "filter by state" do
    let!(:idea) { create(:idea, title: idea_title, component:) }
    let!(:second_idea) { create(:idea, :evaluating, title: second_idea_title, component:) }
    let!(:third_idea) { create(:idea, :accepted, title: third_idea_title, component:) }
    let!(:fourth_idea) { create(:idea, :rejected, title: fourth_idea_title, component:) }
    let!(:fifth_idea) { create(:idea, :withdrawn, title: fifth_idea_title, component:) }

    before do
      click_on "Filter"
      find("a", text: "State").hover
    end

    it "shows unanswered ideas" do
      click_on "Not answered"
      hides_filtered(titles, idea_title)
    end

    it "shows ideas where state is evaluating" do
      click_on "Evaluating"
      hides_filtered(titles, second_idea_title)
    end

    it "shows accepted ideas" do
      click_on "Accepted to the next step"
      hides_filtered(titles, third_idea_title)
    end

    it "shows ideas which arent accepted to the next step" do
      click_on "Not accepted to the next step"
      hides_filtered(titles, fourth_idea_title)
    end

    it "shows withdrawn ideas" do
      click_on "Withdrawn"
      hides_filtered(titles, fifth_idea_title)
    end
  end

  describe "filter by area" do
    let!(:idea) { create(:idea, area_scope:, title: idea_title, component:) }
    let!(:second_idea) { create(:idea, area_scope: second_area_scope, title: second_idea_title, component:) }
    let(:area_scope) { create(:scope, parent: parent_area_scope, organization:) }
    let(:second_area_scope) { create(:scope, parent: parent_area_scope, organization:) }

    before do
      visit current_path
      click_on "Filter"

      within ".menu.submenu" do
        find("a", text: "Area").hover
      end
    end

    it "filters by area" do
      click_on area_scope.name["en"]
      hides_filtered([idea.title, second_idea.title], idea.title)
    end
  end

  describe "filter by category" do
    let!(:idea) { create(:idea, category:, title: idea_title, component:) }
    let!(:second_idea) { create(:idea, category: second_category, title: second_idea_title, component:) }
    let(:category) { create(:category, participatory_space: participatory_process) }
    let(:second_category) { create(:category, participatory_space: participatory_process) }

    before do
      visit current_path
      click_on "Filter"
      find("a", text: "Category").hover
    end

    it "filters by category" do
      click_on second_category.name["en"]
      hides_filtered([idea.title, second_idea.title], second_idea.title)
    end
  end

  def hides_filtered(titles, unfiltered_title)
    titles.each do |title|
      if title == unfiltered_title
        expect(page).to have_content(title)
        next
      end
      expect(page).to have_no_content(title)
    end
  end

  # rubocop:enable RSpec/NoExpectationExample
end
