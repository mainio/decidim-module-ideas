# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Ideas
    describe AreaScopesHelper do
      let(:organization) { create(:organization) }
      let(:participatory_space) { create(:participatory_process, :with_steps, organization:) }
      let(:component) { create(:idea_component, participatory_space:) }
      let(:taxonomy_filter) { create(:idea_taxonomy_filter, organization:) }

      # The filter's root taxonomy has 5 children created by the factory.
      # Grab them so we can reference them in tests.
      let(:child_taxonomies) { taxonomy_filter.filter_items.map(&:taxonomy_item) }

      before do
        allow(helper).to receive(:current_component).and_return(component)
        allow(helper).to receive(:current_locale).and_return("en")
      end

      describe "#area_scopes_parent" do
        context "when the component has no area_taxonomy_filter_id set" do
          it "returns nil" do
            expect(helper.area_scopes_parent(component)).to be_nil
          end
        end

        context "when the component has an area_taxonomy_filter_id set" do
          before do
            component.settings = component.settings.to_h.merge(area_taxonomy_filter_id: taxonomy_filter.id)
            component.save
          end

          it "returns the TaxonomyFilter" do
            expect(helper.area_scopes_parent(component)).to eq(taxonomy_filter)
          end

          it "returns nil when the filter id points to a non-existent record" do
            component.settings = component.settings.to_h.merge(area_taxonomy_filter_id: 0)
            component.save
            expect(helper.area_scopes_parent(component)).to be_nil
          end
        end
      end

      describe "#has_visible_area_scope?" do
        let(:idea) { create(:idea, component:) }

        context "when the component has no area_taxonomy_filter_id set" do
          it "returns false" do
            expect(helper.has_visible_area_scope?(idea)).to be(false)
          end
        end

        context "when the component has a filter but the idea has no taxonomies" do
          before do
            component.settings = component.settings.to_h.merge(area_taxonomy_filter_id: taxonomy_filter.id)
            component.save
            idea.taxonomizations.destroy_all
            idea.reload
          end

          it "returns false" do
            expect(helper.has_visible_area_scope?(idea)).to be(false)
          end
        end

        context "when the idea has a taxonomy that belongs to the filter" do
          before do
            component.settings = component.settings.to_h.merge(area_taxonomy_filter_id: taxonomy_filter.id)
            component.save
            idea.taxonomizations.destroy_all
            idea.taxonomizations.create!(taxonomy: child_taxonomies.first)
            idea.reload
          end

          it "returns true" do
            expect(helper.has_visible_area_scope?(idea)).to be(true)
          end
        end

        context "when the idea has taxonomies that do not belong to the filter" do
          let(:other_root) { create(:taxonomy, organization: component.organization) }
          let(:other_taxonomy) { create(:taxonomy, organization: component.organization, parent: other_root) }

          before do
            component.settings = component.settings.to_h.merge(area_taxonomy_filter_id: taxonomy_filter.id)
            component.save
            idea.taxonomizations.destroy_all
            idea.taxonomizations.create!(taxonomy: other_taxonomy)
            idea.reload
          end

          it "returns false" do
            expect(helper.has_visible_area_scope?(idea)).to be(false)
          end
        end
      end

      describe "#area_scopes_default_coordinates" do
        context "when the component has no filter set" do
          it "returns an empty hash" do
            expect(helper.area_scopes_default_coordinates(component)).to eq({})
          end
        end

        context "when the component has a filter set" do
          before do
            component.settings = component.settings.to_h.merge(area_taxonomy_filter_id: taxonomy_filter.id)
            component.save
          end

          it "returns a hash keyed by taxonomy id strings with empty string values" do
            result = helper.area_scopes_default_coordinates(component)
            expect(result).to be_a(Hash)
            child_taxonomies.each do |taxonomy|
              expect(result).to have_key(taxonomy.id.to_s)
              expect(result[taxonomy.id.to_s]).to eq("")
            end
          end
        end
      end

      describe "#area_scopes_coordinates" do
        before do
          component.settings = component.settings.to_h.merge(area_taxonomy_filter_id: taxonomy_filter.id)
          component.save
        end

        context "when no custom coordinates are stored in the component settings" do
          it "returns the default coordinates" do
            result = helper.area_scopes_coordinates(component)
            expect(result).to eq(helper.area_scopes_default_coordinates(component))
          end
        end

        context "when custom coordinates are stored in the component settings" do
          let(:custom_coords) { { child_taxonomies.first.id.to_s => "60.1699,24.9384" } }

          before do
            component.settings = component.settings.to_h.merge(area_scope_coordinates: custom_coords)
            component.save
          end

          it "merges custom coordinates over the defaults" do
            result = helper.area_scopes_coordinates(component)
            expect(result[child_taxonomies.first.id.to_s]).to eq("60.1699,24.9384")
          end

          it "still includes default (empty) entries for other taxonomies" do
            result = helper.area_scopes_coordinates(component)
            remaining = child_taxonomies.reject { |t| t.id == child_taxonomies.first.id }
            remaining.each do |t|
              expect(result).to have_key(t.id.to_s)
            end
          end
        end
      end

      describe "#area_scopes_picker_field" do
        let(:form) { double("form") }

        context "when no filter is configured" do
          it "returns nil" do
            expect(helper.area_scopes_picker_field(form, :area_scope_id)).to be_nil
          end
        end

        context "when a filter is configured" do
          before do
            component.settings = component.settings.to_h.merge(area_taxonomy_filter_id: taxonomy_filter.id)
            component.save
          end

          it "delegates to form.select with the taxonomy options" do
            expected_options = helper.send(:area_scopes_options, taxonomy_filter.taxonomies)
            expect(form).to receive(:select).with(:area_scope_id, expected_options, {}, {})
            helper.area_scopes_picker_field(form, :area_scope_id)
          end
        end
      end

      describe "#area_scopes_picker_tag" do
        context "when no filter is configured" do
          it "returns nil" do
            expect(helper.area_scopes_picker_tag(:area_scope_id, nil)).to be_nil
          end
        end

        context "when a filter is configured" do
          before do
            component.settings = component.settings.to_h.merge(area_taxonomy_filter_id: taxonomy_filter.id)
            component.save
          end

          it "renders a select tag" do
            rendered = helper.area_scopes_picker_tag("filter[area_scope_id]", child_taxonomies.first.id)
            expect(rendered).to include("select")
            expect(rendered).to include("filter[area_scope_id]")
          end

          it "marks the passed value as selected" do
            selected_id = child_taxonomies.first.id
            rendered = helper.area_scopes_picker_tag("filter[area_scope_id]", selected_id)
            expect(rendered).to include("selected")
          end
        end
      end

      describe "#area_scopes_picker_filter" do
        let(:form) { double("form") }

        context "when no filter is configured" do
          it "returns nil" do
            expect(helper.area_scopes_picker_filter(form, :area_scope_id)).to be_nil
          end
        end

        context "when a filter is configured" do
          before do
            component.settings = component.settings.to_h.merge(area_taxonomy_filter_id: taxonomy_filter.id)
            component.save
          end

          it "behaves identically to area_scopes_picker_field" do
            expected_options = helper.send(:area_scopes_options, taxonomy_filter.taxonomies)
            expect(form).to receive(:select).with(:area_scope_id, expected_options, {}, {})
            helper.area_scopes_picker_filter(form, :area_scope_id)
          end
        end
      end
    end
  end
end
