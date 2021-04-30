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
  let(:scope) { create :scope, organization: organization }
  let!(:subscope) { create :scope, parent: scope }
  let!(:category) { create :category, participatory_space: participatory_process }

  let(:idea_title) { ::Faker::Lorem.paragraph }
  let(:idea_body) { ::Faker::Lorem.paragraph }

  def visit_component
    page.visit main_component_path(component)
  end

  context "when user isnt signed in" do
    it "shows disabled form" do
      visit "/processes/#{participatory_process.slug}/f/#{component.id}/ideas/new"
      expect(page).to have_content("You need to sign in before submitting an idea")
      expect(page).to have_field "idea[title]", disabled: true
      expect(page).to have_field "idea[body]", disabled: true
    end
  end

  context "when ideas component has parent scope" do
    before do
      component[:settings]["global"]["area_scope_parent_id"] = scope.id
      component.save!
      login_as user, scope: :user
      visit_component
    end

    describe "idea creation process" do
      before do
        click_link "New idea"
        fill_in :idea_title, with: idea_title
        find(:css, "#idea_terms_agreed").set(true)
        fill_in :idea_body, with: idea_body
        select subscope.name["en"], from: :idea_area_scope_id
        select category.name["en"], from: :idea_category_id
      end

      describe "draft" do
        let(:updated_title) { ::Faker::Lorem.paragraph }

        before do
          click_button "Save as draft"
        end

        it "create" do
          expect(page).to have_content("Idea successfully created. Saved as a Draft")
        end

        it "update" do
          fill_in :idea_title, with: updated_title
          click_button "Save as draft"
          expect(page).to have_content("Idea draft successfully updated")
          expect(Decidim::Ideas::Idea.last.title).to eq(updated_title)
        end

        it "publish" do
          fill_in :idea_title, with: updated_title
          click_button "Preview"
          click_button "Publish"
          expect(page).to have_content("Idea successfully published")
        end

        it "withdraw" do
          click_link "Discard this draft"
          click_link "OK"
          expect(page).to have_content("Draft destroyed successfully")
        end
      end

      it "creates a new idea with a category and scope" do
        click_button "Continue"
        click_button "Publish"
        expect(page).to have_content("Idea successfully published")
      end

      context "when uploading a file", processing_uploads_for: Decidim::Ideas::AttachmentUploader do
        it "creates a new idea with image" do
          click_button "Add an image for the idea"
          attach_file(:idea_image_file, Decidim::Dev.asset("avatar.jpg"))
          fill_in :idea_image_title, with: "Foo bar"
          click_button "Add image"
          click_button "Continue"
          click_button "Publish"
          expect(page).to have_content("Idea successfully published")
        end
      end
    end
  end

  context "when component has info texts" do
    let(:terms_intro) { { "en" => ::Faker::Lorem.sentence } }
    let(:terms_text) { { "en" => ::Faker::Lorem.paragraph } }
    let(:areas_info_intro) { { "en" => ::Faker::Lorem.sentence } }
    let(:areas_info_text) { { "en" => ::Faker::Lorem.paragraph } }
    let(:categories_info_intro) { { "en" => ::Faker::Lorem.sentence } }
    let(:categories_info_text) { { "en" => ::Faker::Lorem.paragraph } }

    before do
      component[:settings]["global"]["area_scope_parent_id"] = scope.id
      settings = component.settings
      settings.terms_intro = terms_intro
      settings.terms_text = terms_text
      settings.areas_info_intro = areas_info_intro
      settings.areas_info_text = areas_info_text
      settings.categories_info_intro = categories_info_intro
      settings.categories_info_text = categories_info_text
      component.settings = settings
      component.save!
      login_as user, scope: :user
      visit_component
      click_link "New idea"
    end

    it "shows terms" do
      click_link "Show criteria"
      expect(page).to have_content(terms_intro["en"])
      expect(page).to have_content(terms_text["en"])
    end

    it "shows area info" do
      click_link "Check which neighborhood belong to different major districts"
      expect(page).to have_content(areas_info_intro["en"])
      expect(page).to have_content(areas_info_text["en"])
    end

    it "shows category info" do
      click_link "Check what the themes consist of"
      expect(page).to have_content(categories_info_intro["en"])
      expect(page).to have_content(categories_info_text["en"])
    end
  end
end
