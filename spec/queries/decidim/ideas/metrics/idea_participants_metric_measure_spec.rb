# frozen_string_literal: true

require "spec_helper"

describe Decidim::Ideas::Metrics::IdeaParticipantsMetricMeasure do
  let(:day) { Time.zone.yesterday }
  let(:organization) { create(:organization, tos_version: Time.current) }
  let(:not_valid_resource) { create(:dummy_resource) }
  let(:participatory_space) { create(:participatory_process, :with_steps, organization:) }

  let(:ideas_component) { create(:idea_component, :published, participatory_space:) }
  let!(:idea) { create(:idea, published_at: day, component: ideas_component) }
  let!(:old_idea) { create(:idea, published_at: day - 1.week, component: ideas_component) }
  let!(:old_idea2) { create(:idea, published_at: day - 2.days, component: ideas_component) }

  context "when executing class" do
    it "fails to create object with an invalid resource" do
      manager = described_class.new(day, not_valid_resource)

      expect(manager).not_to be_valid
    end

    it "calculates" do
      result = described_class.new(day, ideas_component).calculate

      expect(result[:cumulative_users].count).to eq(3)
      expect(result[:quantity_users].count).to eq(1)
    end

    it "does not found any result for past days" do
      result = described_class.new(day - 1.month, ideas_component).calculate

      expect(result[:cumulative_users].count).to eq(0)
      expect(result[:quantity_users].count).to eq(0)
    end
  end
end
