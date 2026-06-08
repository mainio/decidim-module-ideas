# frozen_string_literal: true

shared_context "with idea taxonomy filter" do
  let(:root_taxonomy) { create(:taxonomy, organization:, name: { "en" => "Root taxonomy" }) }
  let(:taxonomy_filter) do
    create(:taxonomy_filter,
           root_taxonomy:,
           participatory_space_manifests: [participatory_space.manifest.name],
           internal_name: { "en" => "Ideas taxonomy filter" },
           name: { "en" => "Ideas taxonomy filter" })
  end
  let(:taxonomy) { create(:taxonomy, parent: root_taxonomy, organization:, name: { "en" => "Test taxonomy" }) }
  let(:other_taxonomy) { create(:taxonomy, parent: root_taxonomy, organization:, name: { "en" => "Other taxonomy" }) }
  let(:another_taxonomy) { create(:taxonomy, parent: root_taxonomy, organization:, name: { "en" => "Another taxonomy" }) }

  let!(:taxonomy_filter_item) { create(:taxonomy_filter_item, taxonomy_filter:, taxonomy_item: taxonomy) }
  let!(:other_taxonomy_filter_item) { create(:taxonomy_filter_item, taxonomy_filter:, taxonomy_item: other_taxonomy) }
  let!(:another_taxonomy_filter_item) { create(:taxonomy_filter_item, taxonomy_filter:, taxonomy_item: another_taxonomy) }

  before do
    component.settings = component.settings.to_h.merge(taxonomy_filters: [taxonomy_filter.id.to_s])
    component.save!
  end
end