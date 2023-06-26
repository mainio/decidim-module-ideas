# frozen_string_literal: true

require "spec_helper"

describe "User browses ideas", type: :system do
  include_context "with a component"

  let(:organization) { create :organization }
  let(:participatory_process) { create :participatory_process, :with_steps, organization: organization }
  let(:manifest) { Decidim.find_component_manifest("ideas") }
  let!(:user) { create :user, :confirmed, organization: organization }
  let!(:component) { create(:idea_component, manifest: manifest, participatory_space: participatory_process) }
  let(:scope) { create :scope, organization: organization }
  let!(:subscope) { create :scope, parent: scope }
  let!(:category) { create :category, participatory_space: participatory_process }
  let!(:comment) { create(:comment, commentable: idea) }

  let!(:idea) { create(:idea, component: component, title: idea_title, body: idea_body, area_scope_parent: scope, category: category) }
  let(:idea_title) { ::Faker::Lorem.paragraph }
  let(:idea_body) { ::Faker::Lorem.paragraph }
  let(:state) { nil }
  let(:answer) { nil }

  before do
    component[:settings]["global"]["area_scope_parent_id"] = scope.id
    settings = component.settings
    settings.area_scope_coordinates = { subscope.id.to_s => "60.1699,24.9384" }
    component.settings = settings
    component.save!
    login_as user, scope: :user
    visit_component
  end

  shared_examples "shows idea" do
    it "shows the idea" do
      click_link idea.title
      expect(page).to have_content(idea.title)
      expect(page).to have_content(idea.body)
      expect(page).to have_content(subscope.name["en"])
      expect(page).to have_content(category.name["en"])
      expect(page).to have_content(comment.body["en"])
    end
  end

  describe "show" do
    it_behaves_like "shows idea"

    context "when idea is answered" do
      let!(:idea2) { create(:idea, :with_answer, state: state, answer: answer, component: component, title: idea2_title, body: idea2_body, area_scope_parent: scope, category: category) }
      let(:answer) { ::Faker::Lorem.paragraph }
      let(:idea2_title) { ::Faker::Hipster.sentence }
      let(:idea2_body) { ::Faker::Hipster.paragraph }

      before do
        visit_component
        click_link idea2_title
      end

      context "when the idea is accepted" do
        let(:state) { "accepted" }

        it "shows answer" do
          expect(page).to have_content("This idea was accepted to the next step")
          expect(page).to have_content(answer)
        end
      end

      context "when the idea is being evaluated" do
        let(:state) { "evaluating" }

        it "shows answer" do
          expect(page).to have_content("This idea is being evaluated")
          expect(page).to have_content(answer)
        end
      end

      context "when the idea is rejected" do
        let(:state) { "rejected" }

        it "shows answer" do
          expect(page).to have_content("This idea was not accepted to the next step")
          expect(page).to have_content(answer)
        end
      end
    end
  end

  describe "report idea" do
    let(:reason) { %w(spam offensive does_not_belong).sample }
    let(:report_body) { ::Faker::Lorem.paragraph }

    it "creates report" do
      click_link idea.title
      click_button "Report idea"
      choose "report[reason]", option: reason
      fill_in "report[details]", with: report_body
      click_button "Report"
      expect(page).to have_content("The report has been created successfully and it will be reviewed by an admin")
      expect(Decidim::Report.last.details).to eq(report_body)
      expect(Decidim::Report.last.reason).to eq(reason)
    end
  end

  describe "comment another user's idea" do
    let!(:idea2) { create(:idea, component: component, users: [create(:user, organization: organization)]) }
    let!(:idea3) { create(:idea, title: idea3_title, body: idea3_body, component: component, users: [create(:user, organization: organization)]) }
    let(:idea3_title) { ::Faker::Lorem.sentence }
    let(:idea3_body) { ::Faker::Lorem.paragraph }
    let(:add_comment) { "Heres link to another idea: http://#{organization.host}/processes/#{participatory_process.slug}/f/#{component.id}/ideas/#{idea3.id}" }

    before do
      visit current_path
    end

    it "follows link" do
      click_link idea2.title
      fill_in "add-comment-Idea-#{idea2.id}", with: add_comment
      click_button "Send"
      click_link idea3_title
      expect(page).to have_content(idea3_body)
      expect(page).to have_content(idea3.category.name["en"])
      expect(page).to have_content(idea3.area_scope.name["en"])
    end
  end
end
