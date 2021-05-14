# frozen_string_literal: true

require "spec_helper"

describe "Admin filters ideas", type: :system do
  include_context "when managing a component"

  let(:organization) { create(:organization) }
  let(:participatory_process) { create(:participatory_process, :with_steps, organization: organization) }
  let!(:component) { create(:idea_component, :with_creation_enabled, manifest: manifest, participatory_space: participatory_process) }
  let(:manifest) { Decidim.find_component_manifest("ideas") }
  let(:user) { create(:user, :admin, :confirmed, organization: organization) }
  let!(:parent_area_scope) { create(:scope, organization: organization) }

  let(:idea_title) { ::Faker::Lorem.sentence }
  let(:idea2_title) { ::Faker::Hipster.sentence }
  let(:idea3_title) { "Palasin juuri uudesta koulustani, sain tänään tietää" }
  let(:idea4_title) { "Mieleni minun tekevi, aivoni ajattelevi lähteäni laulamahan" }
  let(:idea5_title) { "Jukolan talo, eteläisessä Hämeessä, seisoo erään mäen pohjoisella rinteellä" }
  let(:titles) { [idea_title, idea2_title, idea3_title, idea4_title, idea5_title] }

  before do
    component[:settings]["global"]["area_scope_parent_id"] = parent_area_scope.id
    component.save!
    visit_component_admin
  end

  describe "filter by state" do
    let!(:idea) { create(:idea, title: idea_title, component: component) }
    let!(:idea2) { create(:idea, :evaluating, title: idea2_title, component: component) }
    let!(:idea3) { create(:idea, :accepted, title: idea3_title, component: component) }
    let!(:idea4) { create(:idea, :rejected, title: idea4_title, component: component) }
    let!(:idea5) { create(:idea, :withdrawn, title: idea5_title, component: component) }

    before do
      within ".fcell.filter" do
        find(".dropdown.button").hover
      end
      find("a", text: "State").hover
    end

    it "shows unanswered ideas" do
      click_link "Not answered"
      hides_filtered(titles, idea_title)
    end

    it "shows ideas where state is evaluating" do
      click_link "Evaluating"
      hides_filtered(titles, idea2_title)
    end

    it "shows accepted ideas" do
      click_link "Accepted to the next step"
      hides_filtered(titles, idea3_title)
    end

    it "shows ideas which arent accepted to the next step" do
      click_link "Not accepted to the next step"
      hides_filtered(titles, idea4_title)
    end

    it "shows withdrawn ideas" do
      click_link "Withdrawn"
      hides_filtered(titles, idea5_title)
    end
  end

  describe "filter by area" do
    let!(:idea) { create(:idea, area_scope: area_scope, title: idea_title, component: component) }
    let!(:idea2) { create(:idea, area_scope: area_scope2, title: idea2_title, component: component) }
    let(:area_scope) { create(:scope, parent: parent_area_scope, organization: organization) }
    let(:area_scope2) { create(:scope, parent: parent_area_scope, organization: organization) }

    before do
      visit current_path
      within ".fcell.filter" do
        find(".dropdown.button").hover
        find("a", text: "Area").hover
      end
    end

    it "filters by area" do
      click_link area_scope.name["en"]
      hides_filtered([idea.title, idea2.title], idea.title)
    end
  end

  describe "filter by category" do
    let!(:idea) { create(:idea, category: category, title: idea_title, component: component) }
    let!(:idea2) { create(:idea, category: category2, title: idea2_title, component: component) }
    let(:category) { create(:category, participatory_space: participatory_process) }
    let(:category2) { create(:category, participatory_space: participatory_process) }

    before do
      visit current_path
      within ".fcell.filter" do
        find(".dropdown.button").hover
        find("a", text: "Category").hover
      end
    end

    it "filters by category" do
      click_link category2.name["en"]
      hides_filtered([idea.title, idea2.title], idea2.title)
    end
  end

  def hides_filtered(titles, unfiltered_title)
    titles.each do |title|
      if title == unfiltered_title
        expect(page).to have_content(title)
        next
      end
      expect(page).not_to have_content(title)
    end
  end
end
