# frozen_string_literal: true

require "spec_helper"

describe Decidim::Ideas::IdeaActivityCell, type: :cell do
  controller Decidim::LastActivitiesController

  subject { my_cell.call }

  let(:my_cell) { cell("decidim/ideas/idea_activity", action_log) }
  let!(:idea) { create(:idea) }
  let(:action) { :publish }
  let(:action_log) do
    create(
      :action_log,
      action: action,
      resource: idea,
      organization: idea.organization,
      component: idea.component,
      participatory_space: idea.participatory_space
    )
  end

  context "when rendering" do
    it "renders the card" do
      expect(subject).to have_css("#action-#{action_log.id}")
    end

    context "when action is update" do
      let(:action) { :update }

      it "renders the correct title" do
        expect(subject).to have_css("#action-#{action_log.id}")
        expect(subject).to have_content("Idea updated")
      end
    end

    context "when action is create" do
      let(:action) { :create }

      it "renders the correct title" do
        expect(subject).to have_css("#action-#{action_log.id}")
        expect(subject).to have_content("New idea")
      end
    end

    context "when action is publish" do
      it "renders the correct title" do
        expect(subject).to have_css("#action-#{action_log.id}")
        expect(subject).to have_content("New idea")
      end
    end
  end
end
