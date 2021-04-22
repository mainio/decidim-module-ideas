# frozen_string_literal: true

require "spec_helper"

describe "User edits idea", type: :system do
  include_context "with a component"

  let(:organization) { create :organization }
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
  let(:scope) { create :scope, organization: organization }
  let!(:subscope) { create :scope, parent: scope }
  let!(:category) { create :category, participatory_space: participatory_process }

  let(:idea_title) { ::Faker::Lorem.paragraph }
  let(:idea_body) { ::Faker::Lorem.paragraph }

  before do
    component[:settings]["global"]["area_scope_parent_id"] = scope.id
    component.save!
    login_as user, scope: :user
    visit_component
  end

  context "when user has created an idea" do
    let!(:idea) { create :idea, users: [user], component: component, category: category }
    let(:new_title) { "Foo bar, much text here is" }
    let(:new_body) { "Veli kulta, veikkoseni, kaunis kasvinkumppalini! Lähe nyt kanssa laulamahan" }

    describe "edit idea" do
      before do
        visit current_path
        click_link idea.title
        click_link "Edit idea"
      end

      it "edits idea" do
        fill_in :idea_title, with: new_title
        fill_in :idea_body, with: new_body
        select subscope.name["en"], from: :idea_area_scope_id
        select category.name["en"], from: :idea_category_id
        click_button "Save"
        expect(page).to have_content("Idea successfully updated")
        expect(Decidim::Ideas::Idea.last.title).to eq(new_title)
        expect(Decidim::Ideas::Idea.last.body).to eq(new_body)
      end
    end
  end
end
