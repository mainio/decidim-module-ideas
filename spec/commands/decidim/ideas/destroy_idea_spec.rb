# frozen_string_literal: true

require "spec_helper"

describe Decidim::Ideas::DestroyIdea do
  subject { command.call }

  let(:command) { described_class.new(idea, user) }
  let!(:idea) { create(:idea, :draft, component: component, users: [user]) }
  let(:organization) { create(:organization, tos_version: Time.current) }
  let(:participatory_space) { create(:participatory_process, :with_steps, organization: organization) }
  let(:component) { create(:idea_component, participatory_space: participatory_space) }
  let(:user) { create(:user, organization: organization) }

  it "broadcasts ok" do
    expect { subject }.to broadcast(:ok)
  end

  it "destroys the idea" do
    expect { subject }.to change(Decidim::Ideas::Idea, :count).by(-1)
  end

  context "when the idea is not a draft" do
    let!(:idea) { create(:idea, component: component, users: [user]) }

    it "broadcasts invalud" do
      expect { subject }.to broadcast(:invalid)
    end

    it "does not destroy the idea" do
      expect { subject }.not_to change(Decidim::Ideas::Idea, :count)
    end
  end

  context "when the idea is not authored by the user" do
    let!(:idea) { create(:idea, :draft, component: component) }

    it "broadcasts invalud" do
      expect { subject }.to broadcast(:invalid)
    end

    it "does not destroy the idea" do
      expect { subject }.not_to change(Decidim::Ideas::Idea, :count)
    end
  end
end
