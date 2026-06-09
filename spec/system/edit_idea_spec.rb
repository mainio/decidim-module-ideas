# frozen_string_literal: true

require "spec_helper"

describe "UserEditsIdea" do
  include_context "with a component"
  include_context "with idea taxonomy filter"

  let(:organization) { create(:organization) }
  let(:skip_injection) { false }
  let(:participatory_process) { create(:participatory_process, :with_steps, organization:) }
  let(:manifest) { Decidim.find_component_manifest("ideas") }
  let!(:user) { create(:user, :confirmed, organization:) }
  let!(:component) do
    create(:idea_component,
           :with_creation_enabled,
           :with_card_image_allowed,
           :with_geocoding_enabled,
           manifest:,
           participatory_space: participatory_process)
  end

  let(:idea_title) { Faker::Lorem.paragraph }
  let(:idea_body) { Faker::Lorem.paragraph }

  before do
    settings = component.settings
    settings.attachments_allowed = true
    component.settings = settings
    component.save!
    login_as user, scope: :user
    visit_component
  end

  context "when user has created an idea" do
    let!(:idea) { create(:idea, users: [user], component:, category: false, area_scope: false, taxonomies: [taxonomy]) }
    let(:new_title) { "Foo bar, much text here is" }
    let(:new_body) { "Veli kulta, veikkoseni, kaunis kasvinkumppalini! Lähe nyt kanssa laulamahan" }

    describe "edit idea" do
      before do
        visit current_path
        click_on idea.title
        click_on "Edit idea"
      end

      it "edits idea" do
        fill_in :idea_title, with: new_title
        fill_in :idea_body, with: new_body
        select other_taxonomy.name["en"], from: "taxonomy_filter_#{taxonomy_filter.id}"
        click_on "Save"
        expect(page).to have_content("Idea successfully updated")
        expect(idea.reload.taxonomies).to include(other_taxonomy)
      end

      context "when editing attachments", processing_uploads_for: Decidim::Ideas::AttachmentUploader do
        let(:add_attachment_title) { Faker::Hipster.sentence }

        it "adds image" do
          dynamically_attach_file(:idea_images, Decidim::Dev.asset("avatar.jpg"), title: add_attachment_title)
          click_on "Save"
          expect(page).to have_content("Idea successfully updated")
          expect(idea.attachments.last.content_type).to eq("image/jpeg")
          expect(idea.attachments.last.title["en"]).to eq(add_attachment_title)
        end

        it "adds document" do
          dynamically_attach_file(:idea_actual_attachments, Decidim::Dev.asset("Exampledocument.pdf"), title: add_attachment_title)
          click_on "Save"
          expect(page).to have_content("Idea successfully updated")
          expect(idea.reload.attachments.last.content_type).to eq("application/pdf")
        end
      end
    end
  end

  context "when idea has image attached" do
    let!(:second_idea) do
      create(:idea,
             :with_photo,
             users: [user],
             title: second_idea_title,
             component:,
             category: false,
             area_scope: false)
    end
    let(:second_idea_title) { Faker::Hipster.sentence }

    describe "remove image" do
      before do
        visit current_path
        scroll_to find_all(".cards-list").last
        within "#idea_#{second_idea.id}" do
          click_on second_idea_title
        end
        click_on "Edit idea"
      end

      it "remove image" do
        attachment_count = second_idea.attachments.count
        click_on "Change image"
        within ".upload-modal" do
          click_on "Remove"
          click_on "Save"
        end
        click_on "Save"
        expect(page).to have_content("Idea successfully updated")
        expect(second_idea.attachments.count).to eq(attachment_count - 1)
      end
    end
  end

  context "when idea has document attached" do
    let!(:third_idea) do
      create(:idea,
             :with_document,
             users: [user],
             title: third_idea_title,
             component:,
             category: false,
             area_scope: false)
    end
    let(:third_idea_title) { Faker::Hipster.sentence }

    describe "remove document" do
      before do
        visit current_path
        within "#idea_#{third_idea.id}" do
          click_on third_idea_title
        end
        click_on "Edit idea"
      end

      it "removes attached pdf" do
        attachment_count = third_idea.attachments.count
        click_on "Change attachment"
        within ".upload-modal" do
          click_on "Remove"
          click_on "Save"
        end
        click_on "Save"
        expect(page).to have_content("Idea successfully updated")
        expect(third_idea.attachments.count).to eq(attachment_count - 1)
      end
    end
  end
end
