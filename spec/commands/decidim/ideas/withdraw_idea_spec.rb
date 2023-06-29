# frozen_string_literal: true

require "spec_helper"

describe Decidim::Ideas::WithdrawIdea do
  subject { command.call }

  let(:command) { described_class.new(idea, user) }
  let!(:idea) { create(:idea, component: component, users: [user]) }
  let(:organization) { create(:organization, tos_version: Time.current) }
  let(:participatory_space) { create(:participatory_process, :with_steps, organization: organization) }
  let(:component) { create(:idea_component, participatory_space: participatory_space) }
  let(:user) { create(:user, :confirmed, organization: organization) }

  it "broadcasts ok" do
    expect { subject }.to broadcast(:ok)
  end

  it "destroys the idea" do
    expect { subject }.to change(idea, :state).to("withdrawn")
  end
end
