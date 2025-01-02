# frozen_string_literal: true

require "spec_helper"

describe "UserFiltersIdeas" do
  include_context "with a component"

  let(:organization) { create(:organization, *organization_traits, available_locales: [:en]) }
  let(:participatory_process) { create(:participatory_process, :with_steps, organization:) }
  let(:manifest_name) { "ideas" }
  let(:manifest) { Decidim.find_component_manifest(manifest_name) }
  let!(:user) { create(:user, :confirmed, organization:) }
  let!(:component) do
    create(:idea_component,
           :with_creation_enabled,
           :with_card_image_allowed,
           :with_attachments_allowed,
           :with_geocoding_enabled,
           manifest:,
           participatory_space: participatory_process)
  end
  let(:organization_traits) { [] }
  let(:area_scope_parent) { create(:area_scope_parent, organization:) }
  let!(:category) { create(:category, participatory_space: participatory_process) }

  let(:idea_title) { Faker::Lorem.paragraph }
  let(:idea_body) { Faker::Lorem.paragraph }

  let(:title) { "First idea's title is here" }
  let(:second_title) { "Foo bar some text here is" }
  let(:third_title) { "Force is strong with this one" }

  shared_examples "has clear filters button" do
    it "clears filters" do
      click_on "Clear filters"
      perform_search
      expect(page).to have_content(idea.title)
      expect(page).to have_content(second_idea.title)
      expect(page).to have_content(third_idea.title)
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
    let!(:idea) { create(:idea, component:, title:) }
    let!(:second_idea) { create(:idea, component:, title: second_title) }
    let!(:third_idea) { create(:idea, :rejected, component:, title: third_title) }

    before do
      visit current_path
      within all(".filters__control.area_scope_id_filter").first do
        fill_in "filter[search_text_cont]", with: title
      end
      perform_search
    end

    it "can search" do
      expect(page).to have_content(title)
      expect(page).to have_no_content(second_title)
      expect(page).to have_no_content(third_title)
    end

    it_behaves_like "has clear filters button"
  end

  describe "evaluation" do
    let!(:idea) { create(:idea, :evaluating, component:, title:) }
    let!(:second_idea) { create(:idea, :accepted, component:, title: second_title) }
    let!(:third_idea) { create(:idea, :rejected, component:, title: third_title) }

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
        expect(page).to have_content(second_title)
        expect(page).to have_no_content(title)
        expect(page).to have_no_content(third_title)
      end
    end

    it "shows not accepted to the next step" do
      select "Not accepted to the next step", from: "filter[with_any_state]"
      perform_search
      expect(page).to have_content(third_title)
      expect(page).to have_no_content(title)
      expect(page).to have_no_content(second_title)
    end

    it "shows not answered" do
      select "Not answered", from: "filter[with_any_state]"
      perform_search
      expect(page).to have_content(title)
      expect(page).to have_no_content(second_title)
      expect(page).to have_no_content(third_title)
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
        expect(page).to have_no_content("EVALUATION")
      end
    end
  end

  describe "area" do
    let!(:idea) { create(:idea, component:, title:) }
    let!(:second_idea) { create(:idea, component:, title: second_title) }
    let!(:third_idea) { create(:idea, component:, title: third_title) }

    before do
      component[:settings]["global"]["area_scope_parent_id"] = area_scope_parent.id
      component.save!
      Decidim::Ideas::Idea.update(idea.id, area_scope: area_scope_parent.children.first)
      Decidim::Ideas::Idea.update(second_idea.id, area_scope: area_scope_parent.children.second)
      Decidim::Ideas::Idea.update(third_idea.id, area_scope: area_scope_parent.children.third)
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
        expect(page).to have_no_content(second_idea.title)
        expect(page).to have_no_content(third_idea.title)
      end
    end
  end

  describe "category" do
    let!(:idea) { create(:idea, category:, component:, title:) }
    let!(:second_idea) { create(:idea, category: second_category, component:, title: second_title) }
    let!(:third_idea) { create(:idea, category: third_category, component:, title: third_title) }
    let(:category) { create(:category, participatory_space: component.participatory_space) }
    let(:second_category) { create(:category, participatory_space: component.participatory_space) }
    let(:third_category) { create(:category, participatory_space: component.participatory_space) }

    describe "category selected" do
      before do
        visit current_path
        select category.name["en"], from: "filter[with_category]"
        perform_search
      end

      it_behaves_like "has clear filters button"

      it "shows ideas in the selected theme" do
        expect(page).to have_content(idea.title)
        expect(page).to have_no_content(second_idea.title)
        expect(page).to have_no_content(third_idea.title)
      end
    end
  end

  describe "order" do
    context "when there are ideas with comments" do
      let!(:idea) { create(:idea, component:, title:) }
      let!(:second_idea) { create(:idea, component:, title: second_title) }
      let!(:third_idea) { create(:idea, :rejected, component:, title: third_title) }
      let!(:comment) { create(:comment, commentable: second_idea) }
      let!(:second_comment) { create(:comment, commentable: second_idea) }
      let!(:third_comment) { create(:comment, commentable: third_idea) }

      before do
        visit current_path
        within ".order-by" do
          expect(page).to have_css("a[data-order='recent']", text: "Recent")
          page.find("a", text: "Recent").click
          click_on(selected_option, match: :first)
        end
        within ".order-by" do
          expect(page).to have_content(selected_option)
        end
        expect(page).to have_content("Browse ideas", wait: 1)
      end

      describe "select recent" do
        let(:selected_option) { "Recent" }

        it "shows newest first" do
          expect(page).to have_content(/#{third_title}.*#{second_title}.*#{title}/m)
        end
      end

      describe "select oldest" do
        let(:selected_option) { "Oldest" }

        it "shows oldest first" do
          expect(page).to have_content(/#{title}.*#{second_title}.*#{third_title}/m)
        end
      end

      describe "select most commented" do
        let(:selected_option) { "Most commented" }

        it "shows most commented first" do
          expect(page).to have_content(/#{second_title}.*#{third_title}.*#{title}/m)
        end
      end
    end
  end

  def perform_search
    within all(".filters__actions")[-1] do
      find("*[type=submit]").click
    end
  end
end
