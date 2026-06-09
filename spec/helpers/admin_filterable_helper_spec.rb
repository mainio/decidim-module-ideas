# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Ideas
    module Admin
      describe FilterableHelper do
        let(:organization) { create(:organization) }
        let(:taxonomy_filter) { create(:idea_taxonomy_filter, organization:) }

        describe "#extra_dropdown_submenu_options_items" do
          let(:i18n_scope) { "decidim.ideas.admin.ideas.filters" }

          context "when filter is :state_eq" do
            it "returns a single li element" do
              allow(helper).to receive(:filter_link_value).and_return("link")
              result = helper.extra_dropdown_submenu_options_items(:state_eq, i18n_scope)
              expect(result.length).to eq(1)
              expect(result.first).to include("<li>")
            end
          end

          context "when filter is an unrecognised key" do
            it "returns an empty array" do
              result = helper.extra_dropdown_submenu_options_items(:unknown_filter, i18n_scope)
              expect(result).to eq([])
            end
          end
        end

        describe "#grouped_filter_taxonomies" do
          # The :idea_taxonomy_filter factory creates a root taxonomy with 5 direct
          # children, each added as a filter item. All children share the same
          # parent_id (root_taxonomy_id), so by default they all fall into the
          # flat "else" branch.
          context "when all taxonomy items are direct children of the root" do
            it "returns each child as a top-level group entry" do
              result = helper.grouped_filter_taxonomies(taxonomy_filter)
              child_ids = taxonomy_filter.filter_items.map(&:taxonomy_item_id)

              expect(result.keys).to match_array(child_ids)
            end

            it "each group entry has an empty children hash" do
              result = helper.grouped_filter_taxonomies(taxonomy_filter)
              result.each_value do |group|
                expect(group[:children]).to eq({})
              end
            end

            it "each group entry carries the correct taxonomy object" do
              result = helper.grouped_filter_taxonomies(taxonomy_filter)
              result.each do |id, group|
                expect(group[:taxonomy].id).to eq(id)
              end
            end
          end

          context "when a filter item has a grandparent (parent not in filter, not root)" do
            # Build a three-level tree: root → mid → leaf
            # Only the leaf is added to the filter. mid is not in the filter and
            # is not the root, so the leaf should be grouped under mid.
            let(:root_taxonomy) { taxonomy_filter.root_taxonomy }
            let(:mid_taxonomy) { create(:taxonomy, organization:, parent: root_taxonomy) }
            let(:leaf_taxonomy) { create(:taxonomy, organization:, parent: mid_taxonomy) }

            let(:deep_filter) do
              filter = create(:taxonomy_filter, root_taxonomy:)
              create(:taxonomy_filter_item, taxonomy_filter: filter, taxonomy_item: leaf_taxonomy)
              filter
            end

            it "groups the leaf under its intermediate parent" do
              result = helper.grouped_filter_taxonomies(deep_filter)

              expect(result).to have_key(mid_taxonomy.id)
              expect(result[mid_taxonomy.id][:taxonomy]).to eq(mid_taxonomy)
              expect(result[mid_taxonomy.id][:children]).to have_key(leaf_taxonomy.id)
            end

            it "does not create a top-level entry for the leaf itself" do
              result = helper.grouped_filter_taxonomies(deep_filter)
              expect(result).not_to have_key(leaf_taxonomy.id)
            end
          end

          context "when the intermediate parent taxonomy no longer exists" do
            # Covers the `next unless parent` guard — if the parent record has
            # been deleted, the child is silently skipped.
            let(:root_taxonomy) { taxonomy_filter.root_taxonomy }
            let(:mid_taxonomy) { create(:taxonomy, organization:, parent: root_taxonomy) }
            let(:leaf_taxonomy) { create(:taxonomy, organization:, parent: mid_taxonomy) }

            let(:deep_filter) do
              filter = create(:taxonomy_filter, root_taxonomy:)
              create(:taxonomy_filter_item, taxonomy_filter: filter, taxonomy_item: leaf_taxonomy)
              filter
            end

            before do
              # Detach leaf from mid so destroy doesn't cascade, then destroy mid
              leaf_taxonomy.update(parent_id: mid_taxonomy.id)
              mid_taxonomy.delete
            end

            it "skips the item without raising" do
              expect { helper.grouped_filter_taxonomies(deep_filter) }.not_to raise_error
            end

            it "does not include the orphaned leaf in the result" do
              result = helper.grouped_filter_taxonomies(deep_filter)
              expect(result).not_to have_key(leaf_taxonomy.id)
              expect(result).not_to have_key(mid_taxonomy.id)
            end
          end
        end
      end
    end
  end
end
