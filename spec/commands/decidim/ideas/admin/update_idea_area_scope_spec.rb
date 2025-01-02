# frozen_string_literal: true

require "spec_helper"

describe Decidim::Ideas::Admin::UpdateIdeaAreaScope do
  subject { command.call }

  let(:command) { described_class.new(area_scope&.id, ideas.map(&:id)) }
  let!(:ideas) { create_list(:idea, 10, component:) }
  let(:organization) { create(:organization, tos_version: Time.current) }
  let(:participatory_space) { create(:participatory_process, :with_steps, organization:) }
  let(:component) { create(:idea_component, participatory_space:) }
  let(:area_scope) { create(:scope, organization:) }

  it "broadcasts ok" do
    expect { subject }.to broadcast(:update_ideas_scope)
  end

  it "updates the area scopes" do
    expect { subject }.not_to change(Decidim::Ideas::Idea, :count)

    ideas.each do |idea|
      expect(idea.reload.area_scope).to eq(area_scope)
    end
  end

  context "when scope is blank" do
    let(:area_scope) { nil }

    it "does not change anything" do
      expect { subject }.to broadcast(:invalid_scope)

      ideas.each do |idea|
        expect(idea.reload.area_scope).not_to be_nil
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
