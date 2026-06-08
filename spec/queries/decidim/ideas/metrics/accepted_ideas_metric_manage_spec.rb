# frozen_string_literal: true

require "spec_helper"

describe Decidim::Ideas::Metrics::AcceptedIdeasMetricManage do
  let(:organization) { create(:organization, tos_version: Time.current) }
  let(:participatory_space) { create(:participatory_process, :with_steps, organization:) }
  let(:component) { create(:idea_component, :published, participatory_space:) }
  let(:day) { Time.zone.yesterday }
  let(:taxonomy_filter) { create(:idea_taxonomy_filter, organization:) }
  let(:taxonomy) { taxonomy_filter.root_taxonomy.children.first }
  let(:other_taxonomy) { taxonomy_filter.root_taxonomy.children.second }

  let!(:accepted_ideas) do
    create_list(:idea, 3, :accepted, created_at: day, component:, category: false, area_scope: false, taxonomies: [taxonomy])
  end
  let!(:not_accepted_ideas) do
    create_list(:idea, 3, created_at: day, component:, category: false, area_scope: false, taxonomies: [taxonomy])
  end

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
      create(:metric, metric_type: "accepted_ideas", day:, cumulative: 1, quantity: 1,
             organization:, decidim_taxonomy_id: taxonomy.id, participatory_space:)
      registry = generate_metric_registry

      expect(Decidim::Metric.count).to eq(1)
      expect(registry.collect(&:cumulative)).to eq([3])
      expect(registry.collect(&:quantity)).to eq([3])
    end

    context "with multiple taxonomies" do
      let!(:accepted_ideas_other_taxonomy) do
        create_list(:idea, 2, :accepted, created_at: day, component:, category: false, area_scope: false, taxonomies: [other_taxonomy])
      end

      it "creates separate metric records per taxonomy" do
        registry = generate_metric_registry

        expect(registry.length).to eq(2)
        expect(registry.collect(&:cumulative).sort).to eq([2, 3])
      end

      it "only counts accepted ideas per taxonomy" do
        registry = generate_metric_registry

        taxonomy_record = registry.find { |r| r.decidim_taxonomy_id == taxonomy.id }
        other_taxonomy_record = registry.find { |r| r.decidim_taxonomy_id == other_taxonomy.id }

        expect(taxonomy_record.cumulative).to eq(3)
        expect(other_taxonomy_record.cumulative).to eq(2)
      end
    end
  end
end