# frozen_string_literal: true

require "spec_helper"

describe Decidim::Ideas::Admin::UpdateIdeaCategory do
  subject { command.call }

  let(:command) { described_class.new(category&.id, ideas.map(&:id)) }
  let!(:ideas) { create_list(:idea, 10, component:) }
  let(:organization) { create(:organization, tos_version: Time.current) }
  let(:participatory_space) { create(:participatory_process, :with_steps, organization:) }
  let(:component) { create(:idea_component, participatory_space:) }
  let(:category) { create(:category, participatory_space:) }

  it "broadcasts ok" do
    expect { subject }.to broadcast(:update_ideas_category)
  end

  it "updates the area scopes" do
    expect { subject }.not_to change(Decidim::Ideas::Idea, :count)

    ideas.each do |idea|
      expect(idea.reload.category).to eq(category)
    end
  end

  context "when category is blank" do
    let(:category) { nil }

    it "does not change anything" do
      expect { subject }.to broadcast(:invalid_category)

      ideas.each do |idea|
        expect(idea.reload.category).not_to be_nil
      end
    end
  end

  context "when idea IDs are blank" do
    let!(:ideas) { [] }

    it "does not change anything" do
      expect { subject }.to broadcast(:invalid_idea_ids)
    end
  end
end
