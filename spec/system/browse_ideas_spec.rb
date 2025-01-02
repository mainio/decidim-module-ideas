# frozen_string_literal: true

require "spec_helper"

describe "UserBrowsesIdeas" do
  include_context "with a component"

  let(:organization) { create(:organization) }
  let(:participatory_process) { create(:participatory_process, :with_steps, organization:) }
  let(:manifest) { Decidim.find_component_manifest("ideas") }
  let!(:user) { create(:user, :confirmed, organization:) }
  let!(:component) { create(:idea_component, manifest:, participatory_space: participatory_process) }
  let(:scope) { create(:scope, organization:) }
  let!(:subscope) { create(:scope, parent: scope) }
  let!(:category) { create(:category, participatory_space: participatory_process) }
  let!(:comment) { create(:comment, commentable: idea) }

  let!(:idea) { create(:idea, component:, title: idea_title, body: idea_body, area_scope_parent: scope, category:) }
  let(:idea_title) { Faker::Lorem.paragraph }
  let(:idea_body) { Faker::Lorem.paragraph }
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
      click_on idea.title
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
      let!(:second_idea) { create(:idea, :with_answer, state:, answer:, component:, title: second_idea_title, body: second_idea_body, area_scope_parent: scope, category:) }
      let(:answer) { Faker::Lorem.paragraph }
      let(:second_idea_title) { Faker::Hipster.sentence }
      let(:second_idea_body) { Faker::Hipster.paragraph }

      before do
        visit_component
        click_on second_idea_title
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
    let(:report_body) { Faker::Lorem.paragraph }

    it "creates report" do
      click_on idea.title
      click_on "Report"
      choose "report[reason]", option: reason
      fill_in "report[details]", with: report_body

      within "#flagModal-content" do
        click_on "Report"
      end

      expect(page).to have_content("The report has been created successfully and it will be reviewed by an admin")
      expect(Decidim::Report.last.details).to eq(report_body)
      expect(Decidim::Report.last.reason).to eq(reason)
    end
  end

  describe "comment another user's idea" do
    let!(:second_idea) { create(:idea, component:, users: [create(:user, :confirmed, organization:)]) }
    let!(:third_idea) { create(:idea, title: third_idea_title, body: third_idea_body, component:, users: [create(:user, :confirmed, organization:)]) }
    let(:third_idea_title) { Faker::Lorem.sentence }
    let(:third_idea_body) { Faker::Lorem.paragraph }
    let(:add_comment) { "Heres link to another idea: http://#{organization.host}/processes/#{participatory_process.slug}/f/#{component.id}/ideas/#{third_idea.id}" }

    before do
      visit current_path
    end

    it "follows link" do
      click_on second_idea.title
      fill_in "add-comment-Idea-#{second_idea.id}", with: add_comment
      click_on "Publish comment"
      click_on third_idea_title
      expect(page).to have_content(third_idea_body)
      expect(page).to have_content(third_idea.category.name["en"])
      expect(page).to have_content(third_idea.area_scope.name["en"])
    end
  end
end
