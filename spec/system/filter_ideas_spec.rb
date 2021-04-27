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

  def visit_component
    page.visit main_component_path(component)
  end

  before do
    component.save!
    login_as user, scope: :user
    visit_component
  end

  context "when component has several ideas" do
    let(:title) { "First idea's title is here" }
    let(:title2) { "Foo bar some text here is" }
    let(:title3) { "Force is strong with this one" }

    before do
      visit current_path
    end

    describe "search" do
      let!(:idea) { create(:idea, component: component, title: title) }
      let!(:idea2) { create(:idea, component: component, title: title2) }
      let!(:idea3) { create(:idea, :rejected, component: component, title: title3) }

      it "can search" do
        within ".filters__search" do
          fill_in "filter[search_text]", with: title
          find(".icon--magnifying-glass").click
        end
        expect(page).to have_content(title)
        expect(page).not_to have_content(title2)
        expect(page).not_to have_content(title3)
      end
    end

    describe "evaluation" do
      let!(:idea) { create(:idea, :evaluating, component: component, title: title) }
      let!(:idea2) { create(:idea, :accepted, component: component, title: title2) }
      let!(:idea3) { create(:idea, :rejected, component: component, title: title3) }

      it "shows accepted to next step" do
        select "Accepted to the next step", from: "filter[state]"
        expect(page).to have_content(title2)
        expect(page).not_to have_content(title)
        expect(page).not_to have_content(title3)
      end

      it "shows not accepted to the next step" do
        select "Not accepted to the next step", from: "filter[state]"
        expect(page).to have_content(title3)
        expect(page).not_to have_content(title)
        expect(page).not_to have_content(title2)
      end

      it "shows not answered" do
        select "Not answered", from: "filter[state]"
        expect(page).to have_content(title)
        expect(page).not_to have_content(title2)
        expect(page).not_to have_content(title3)
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

      it "shows ideas in the selected area" do
        select area_scope_parent.children.first.name["en"], from: "filter[area_scope_id]"
        expect(page).to have_content(idea.title)
        expect(page).not_to have_content(idea2.title)
        expect(page).not_to have_content(idea3.title)
      end
    end

    describe "category" do
      let!(:idea) { create(:idea, category: category, component: component, title: title) }
      let!(:idea2) { create(:idea, category: category2, component: component, title: title2) }
      let!(:idea3) { create(:idea, category: category3, component: component, title: title3) }
      let(:category) { create(:category, participatory_space: component.participatory_space) }
      let(:category2) { create(:category, participatory_space: component.participatory_space) }
      let(:category3) { create(:category, participatory_space: component.participatory_space) }

      it "shows ideas in the selected theme" do
        select category.name["en"], from: "filter[category_id]"
        expect(page).to have_content(idea.title)
        expect(page).not_to have_content(idea2.title)
        expect(page).not_to have_content(idea3.title)
      end
    end
  end
end
