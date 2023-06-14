# frozen_string_literal: true

require "spec_helper"

describe Decidim::Ideas::Admin::AnswerIdea do
  subject { command.call }

  let(:command) { described_class.new(form, idea) }
  let(:form) { Decidim::Ideas::Admin::IdeaAnswerForm.new(answer: { en: "Good idea." }, internal_state: "accepted") }
  let(:idea) { create(:idea, component: component) }
  let(:component) { create(:idea_component) }
  let(:user) { create(:user, :admin) }

  before do
    allow(form).to receive(:current_component).and_return(component)
    allow(form).to receive(:current_user).and_return(user)
  end

  it "broadcasts ok" do
    expect { subject }.to broadcast(:ok)
  end

  it "changes the state" do
    expect { subject }.to change(idea, :state).to("accepted")
  end

  it "stores the answer time" do
    expect { subject }.to change(idea, :answered_at)
  end

  it "publishes the answer" do
    expect { subject }.to change(idea, :state_published_at)
  end

  context "when the answers are not published immidiately" do
    let(:component) { create(:idea_component, :without_publish_answers_immediately) }

    it "does not publish the answer" do
      expect { subject }.not_to change(idea, :state_published_at)
    end
  end
end
