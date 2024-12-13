# frozen_string_literal: true

require "spec_helper"

describe "User edits idea", type: :system do
  include_context "with a component"

  let(:organization) { create :organization }
  let(:participatory_process) { create :participatory_process, :with_steps, organization: organization }
  let(:manifest) { Decidim.find_component_manifest("ideas") }
  let!(:user) { create :user, :confirmed, organization: organization }
  let!(:component) do
    create(:idea_component,
           :with_creation_enabled,
           :with_card_image_allowed,
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
    settings = component.settings
    settings.attachments_allowed = true
    component.settings = settings
    component.save!
    login_as user, scope: :user
    visit_component
  end

  context "when user has created an idea" do
    let!(:idea) { create :idea, users: [user], component: component, category: category, area_scope_parent: scope }
    let(:new_title) { "Foo bar, much text here is" }
    let(:new_body) { "Veli kulta, veikkoseni, kaunis kasvinkumppalini! Lähe nyt kanssa laulamahan" }
    let!(:subscope2) { create(:scope, parent: scope) }

    describe "edit idea" do
      before do
        visit current_path
        click_link idea.title
        click_link "Edit idea"
      end

      it "edits idea" do
        fill_in :idea_title, with: new_title
        fill_in :idea_body, with: new_body
        select subscope2.name["en"], from: :idea_area_scope_id
        select category.name["en"], from: :idea_category_id
        click_button "Save"
        expect(page).to have_content("Idea successfully updated")
        expect(Decidim::Ideas::Idea.last.title).to eq(new_title)
        expect(Decidim::Ideas::Idea.last.body).to eq(new_body)
      end

      context "when editing attachments", processing_uploads_for: Decidim::Ideas::AttachmentUploader do
        let(:add_attachment_title) { ::Faker::Hipster.sentence }

        it "adds image" do
          dynamically_attach_file(:idea_images, Decidim::Dev.asset("avatar.jpg"), title: add_attachment_title)
          click_button "Save"
          expect(page).to have_content("Idea successfully updated")
          expect(idea.attachments.last.content_type).to eq("image/jpeg")
          expect(idea.attachments.last.title["en"]).to eq(add_attachment_title)
        end

        it "adds document" do
          dynamically_attach_file(:idea_actual_attachments, Decidim::Dev.asset("Exampledocument.pdf"), title: add_attachment_title)
          click_button "Save"
          expect(page).to have_content("Idea successfully updated")
          expect(idea.attachments.last.content_type).to eq("application/pdf")
          expect(idea.attachments.last.title["en"]).to eq(add_attachment_title)
        end
      end
    end
  end

  context "when idea has image attached" do
    let!(:idea2) do
      create(:idea,
             :with_photo,
             users: [user],
             title: idea2_title,
             component: component,
             category: category,
             area_scope_parent: scope)
    end
    let(:idea2_title) { ::Faker::Hipster.sentence }
    let(:weight) { 0 }

    describe "remove image" do
      before do
        visit current_path
        scroll_to find_all(".cards-list").last
        within "#idea_#{idea2.id}" do
          click_link idea2_title
        end
        click_link "Edit idea"
      end

      it "remove image" do
        click_button "Change image"
        within ".upload-modal" do
          click_button "Remove"
          click_button "Save"
        end
        expect { click_button "Save" }.to change(idea2.attachments, :count).by(-1)
        expect(page).to have_content("Idea successfully updated")
      end
    end
  end

  context "when idea has document attached" do
    let!(:idea3) do
      create(:idea,
             :with_document,
             users: [user],
             title: idea3_title,
             component: component,
             category: category,
             area_scope_parent: scope)
    end
    let(:idea3_title) { ::Faker::Hipster.sentence }

    describe "remove document" do
      before do
        visit current_path
        within "#idea_#{idea3.id}" do
          click_link idea3_title
        end
        click_link "Edit idea"
      end

      it "removes attached pdf" do
        click_button "Change attachment"
        within ".upload-modal" do
          click_button "Remove"
          click_button "Save"
        end
        expect { click_button "Save" }.to change(idea3.attachments, :count).by(-1)
        expect(page).to have_content("Idea successfully updated")
      end
    end
  end
end
