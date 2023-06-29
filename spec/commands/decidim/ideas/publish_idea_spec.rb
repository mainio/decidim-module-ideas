# frozen_string_literal: true

require "spec_helper"

describe Decidim::Ideas::PublishIdea do
  subject { command.call }

  let(:command) { described_class.new(idea, user) }
  let!(:idea) { create(:idea, :draft, component: component, users: [user]) }
  let(:organization) { create(:organization, tos_version: Time.current) }
  let(:participatory_space) { create(:participatory_process, :with_steps, organization: organization) }
  let(:component) { create(:idea_component, participatory_space: participatory_space) }
  let(:user) { create(:user, :confirmed, organization: organization) }

  it "broadcasts ok" do
    expect { subject }.to broadcast(:ok)
  end

  it "publishes the idea" do
    expect { subject }.to change(idea, :published_at)
  end

  context "when the idea is not authored by the user" do
    let!(:idea) { create(:idea, :draft, component: component) }

    it "broadcasts invalud" do
      expect { subject }.to broadcast(:invalid)
    end

    it "does not publish the idea" do
      expect { subject }.not_to change(idea, :published_at)
    end
  end
end
