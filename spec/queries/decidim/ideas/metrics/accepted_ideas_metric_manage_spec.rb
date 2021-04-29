# frozen_string_literal: true

require "spec_helper"

describe Decidim::Ideas::Metrics::AcceptedIdeasMetricManage do
  let(:organization) { create(:organization) }
  let(:participatory_space) { create(:participatory_process, :with_steps, organization: organization) }
  let(:component) { create(:idea_component, :published, participatory_space: participatory_space) }
  let(:day) { Time.zone.yesterday }
  let(:category) { create(:category, participatory_space: participatory_space) }
  let!(:accepted_ideas) { create_list(:idea, 3, :accepted, created_at: day, component: component, category: category) }
  let!(:not_accepted_ideas) { create_list(:idea, 3, created_at: day, component: component, category: category) }

  include_context "when managing metrics"

  before do
    Decidim::Metric.destroy_all
  end

  context "when executing" do
    it "creates new metric records" do
      registry = generate_metric_registry

      expect(registry.collect(&:day)).to eq([day])
      expect(registry.collect(&:cumulative)).to eq([3])
      expect(registry.collect(&:quantity)).to eq([3])
    end

    it "does not create any record if there is no data" do
      registry = generate_metric_registry("2017-01-01")

      expect(Decidim::Metric.count).to eq(0)
      expect(registry).to be_empty
    end

    it "updates metric records" do
      # raise "#{category.id} -- #{accepted_ideas.first.category.id} -- #{accepted_ideas.second.category.id} -- #{not_accepted_ideas.first.category.id}"
      create(:metric, metric_type: "accepted_ideas", day: day, cumulative: 1, quantity: 1, organization: organization, category: category, participatory_space: participatory_space)
      registry = generate_metric_registry

      expect(Decidim::Metric.count).to eq(1)
      expect(registry.collect(&:cumulative)).to eq([3])
      expect(registry.collect(&:quantity)).to eq([3])
    end
  end
end
