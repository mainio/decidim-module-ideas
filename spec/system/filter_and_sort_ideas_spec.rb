# frozen_string_literal: true

require "spec_helper"

describe "User filters ideas", type: :system do
  include_context "with a component"

  let(:organization) { create :organization, *organization_traits, available_locales: [:en] }
  let(:participatory_process) { create :participatory_process, :with_steps, organization: organization }
  let(:manifest_name) { "ideas" }
  let(:manifest) { Decidim.find_component_manifest(manifest_name) }
  let!(:user) { create :user, :confirmed, organization: organization }
  let!(:component) do
    create(:idea_component,
           :with_creation_enabled,
           :with_card_image_allowed,
           :with_attachments_allowed,
           :with_geocoding_enabled,
           manifest: manifest,
           participatory_space: participatory_process)
  end
  let(:organization_traits) { [] }
  let(:area_scope_parent) { create(:area_scope_parent, organization: organization) }
  let!(:category) { create :category, participatory_space: participatory_process }

  let(:idea_title) { ::Faker::Lorem.paragraph }
  let(:idea_body) { ::Faker::Lorem.paragraph }

  let(:title) { "First idea's title is here" }
  let(:title2) { "Foo bar some text here is" }
  let(:title3) { "Force is strong with this one" }

  shared_examples "has clear filters button" do
    it "clears filters" do
      click_button "Clear filters"
      perform_search
      expect(page).to have_content(idea.title)
      expect(page).to have_content(idea2.title)
      expect(page).to have_content(idea3.title)
    end
  end

  def visit_component
    page.visit main_component_path(component)
  end

  before do
    component.save!
    login_as user, scope: :user
    visit_component
  end

  describe "search" do
    let!(:idea) { create(:idea, component: component, title: title) }
    let!(:idea2) { create(:idea, component: component, title: title2) }
    let!(:idea3) { create(:idea, :rejected, component: component, title: title3) }

    before do
      visit current_path
      within all(".filters__control.area_scope_id_filter").last do
        fill_in "filter[search_text_cont]", with: title
      end
      perform_search
    end

    it "can search" do
      expect(page).to have_content(title)
      expect(page).not_to have_content(title2)
      expect(page).not_to have_content(title3)
    end

    it_behaves_like "has clear filters button"
  end

  describe "evaluation" do
    let!(:idea) { create(:idea, :evaluating, component: component, title: title) }
    let!(:idea2) { create(:idea, :accepted, component: component, title: title2) }
    let!(:idea3) { create(:idea, :rejected, component: component, title: title3) }

    before do
      visit current_path
    end

    describe "when has filter selected" do
      before do
        select "Accepted to the next step", from: "filter[with_any_state]"
        perform_search
      end

      it_behaves_like "has clear filters button"

      it "shows accepted to next step" do
        expect(page).to have_content(title2)
        expect(page).not_to have_content(title)
        expect(page).not_to have_content(title3)
      end
    end

    it "shows not accepted to the next step" do
      select "Not accepted to the next step", from: "filter[with_any_state]"
      perform_search
      expect(page).to have_content(title3)
      expect(page).not_to have_content(title)
      expect(page).not_to have_content(title2)
    end

    it "shows not answered" do
      select "Not answered", from: "filter[with_any_state]"
      perform_search
      expect(page).to have_content(title)
      expect(page).not_to have_content(title2)
      expect(page).not_to have_content(title3)
    end

    context "when answers are disabled" do
      before do
        component.update!(settings: { idea_answering_enabled: false })
        visit current_path
      end

      after do
        component.update!(settings: { idea_answering_enabled: true })
      end

      it "doesnt show evaluation filters" do
        expect(page).not_to have_content("EVALUATION")
      end
    end
  end

  describe "area" do
    let!(:idea) { create(:idea, component: component, title: title) }
    let!(:idea2) { create(:idea, component: component, title: title2) }
    let!(:idea3) { create(:idea, component: component, title: title3) }

    before do
      component[:settings]["global"]["area_scope_parent_id"] = area_scope_parent.id
      component.save!
      Decidim::Ideas::Idea.update(idea.id, area_scope: area_scope_parent.children.first)
      Decidim::Ideas::Idea.update(idea2.id, area_scope: area_scope_parent.children.second)
      Decidim::Ideas::Idea.update(idea3.id, area_scope: area_scope_parent.children.third)
      visit current_path
    end

    describe "filter selected" do
      before do
        select area_scope_parent.children.first.name["en"], from: "filter[with_any_area_scope]"
        perform_search
      end

      it_behaves_like "has clear filters button"

      it "shows ideas in the selected area" do
        expect(page).to have_content(idea.title)
        expect(page).not_to have_content(idea2.title)
        expect(page).not_to have_content(idea3.title)
      end
    end
  end

  describe "category" do
    let!(:idea) { create(:idea, category: category, component: component, title: title) }
    let!(:idea2) { create(:idea, category: category2, component: component, title: title2) }
    let!(:idea3) { create(:idea, category: category3, component: component, title: title3) }
    let(:category) { create(:category, participatory_space: component.participatory_space) }
    let(:category2) { create(:category, participatory_space: component.participatory_space) }
    let(:category3) { create(:category, participatory_space: component.participatory_space) }

    describe "category selected" do
      before do
        visit current_path
        select category.name["en"], from: "filter[with_category]"
        perform_search
      end

      it_behaves_like "has clear filters button"

      it "shows ideas in the selected theme" do
        expect(page).to have_content(idea.title)
        expect(page).not_to have_content(idea2.title)
        expect(page).not_to have_content(idea3.title)
      end
    end
  end

  describe "order" do
    context "when there are ideas with comments" do
      let!(:idea) { create(:idea, component: component, title: title) }
      let!(:idea2) { create(:idea, component: component, title: title2) }
      let!(:idea3) { create(:idea, :rejected, component: component, title: title3) }
      let!(:comment) { create(:comment, commentable: idea2) }
      let!(:comment2) { create(:comment, commentable: idea2) }
      let!(:comment3) { create(:comment, commentable: idea3) }

      before do
        visit current_path
        within ".order-by" do
          expect(page).to have_selector("ul[data-dropdown-menu$=dropdown-menu]", text: "Recent")
          page.find("a", text: "Recent").click
          click_link(selected_option, match: :first)
        end
        within ".order-by__dropdown .dropdown.menu li.is-dropdown-submenu-parent a" do
          expect(page).to have_content(selected_option)
        end
        expect(page).to have_content("Browse ideas", wait: 1)
      end

      describe "select recent" do
        let(:selected_option) { "Recent" }

        it "shows newest first" do
          expect(page).to have_content(/#{title3}.*#{title2}.*#{title}/m)
        end
      end

      describe "select oldest" do
        let(:selected_option) { "Oldest" }

        it "shows oldest first" do
          expect(page).to have_content(/#{title}.*#{title2}.*#{title3}/m)
        end
      end

      describe "select most commented" do
        let(:selected_option) { "Most commented" }

        it "shows most commented first" do
          expect(page).to have_content(/#{title2}.*#{title3}.*#{title}/m)
        end
      end
    end
  end

  def perform_search
    within all(".filters__actions")[-1] do
      find("button[type='submit']").click
    end
  end
end
