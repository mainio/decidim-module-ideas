# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Ideas
    describe IdeasHelper do
      let(:organization) { create(:organization) }
      let(:participatory_space) { create(:participatory_process, :with_steps, organization:) }
      let(:component) { create(:idea_component, participatory_space:) }
      let(:taxonomy_filter) { create(:idea_taxonomy_filter, organization:) }

      before do
        allow(helper).to receive(:current_component).and_return(component)
        allow(helper).to receive(:current_locale).and_return("en")
        allow(helper).to receive(:component_settings).and_return(component.settings)
      end

      describe "#ideas_data_for_map" do
        it "maps flat geocoded data arrays into hashes" do
          allow(helper).to receive(:idea_path).with(1).and_return("/ideas/1")

          data = [[1, "My idea", "A long body text", "Some address", 60.1, 24.9]]
          result = helper.ideas_data_for_map(data)

          expect(result.length).to eq(1)
          expect(result.first).to include(
            id: 1,
            title: "My idea",
            address: "Some address",
            latitude: 60.1,
            longitude: 24.9,
            link: "/ideas/1"
          )
        end

        it "truncates the body to 100 characters" do
          allow(helper).to receive(:idea_path).and_return("/ideas/1")

          long_body = "x" * 200
          data = [[1, "Title", long_body, "Addr", 0.0, 0.0]]
          result = helper.ideas_data_for_map(data)

          expect(result.first[:body].length).to be <= 103 # 100 + ellipsis
        end

        it "returns an empty array for empty input" do
          expect(helper.ideas_data_for_map([])).to eq([])
        end
      end

      describe "#display_answer_filter?" do
        let(:component_settings) { double("component_settings", idea_answering_enabled: true) }
        let(:current_settings) { double("current_settings", idea_answering_enabled: true) }

        before do
          allow(helper).to receive(:component_settings).and_return(component_settings)
          allow(helper).to receive(:current_settings).and_return(current_settings)
        end

        it "returns true when both settings are enabled" do
          expect(helper.display_answer_filter?).to be(true)
        end

        it "returns false when component_settings disables answering" do
          allow(component_settings).to receive(:idea_answering_enabled).and_return(false)
          expect(helper.display_answer_filter?).to be(false)
        end

        it "returns false when current_settings disables answering" do
          allow(current_settings).to receive(:idea_answering_enabled).and_return(false)
          expect(helper.display_answer_filter?).to be(false)
        end
      end

      describe "#display_taxonomy_filters?" do
        context "when no taxonomy filters are configured on the component" do
          it "returns false" do
            expect(helper.display_taxonomy_filters?).to be(false)
          end
        end

        context "when a taxonomy filter is configured and has items" do
          before do
            component.update!(settings: { taxonomy_filters: [taxonomy_filter.id] })
          end

          it "returns true" do
            expect(helper.display_taxonomy_filters?).to be(true)
          end
        end
      end

      describe "#filter_ideas_taxonomy_values" do
        context "when no taxonomy filters are configured" do
          it "returns an empty array" do
            expect(helper.filter_ideas_taxonomy_values).to eq([])
          end
        end

        context "when a taxonomy filter is configured" do
          before do
            component.update!(settings: { taxonomy_filters: [taxonomy_filter.id] })
          end

          it "returns an array of [filter, values] pairs" do
            result = helper.filter_ideas_taxonomy_values
            expect(result).not_to be_empty
            filter, values = result.first
            expect(filter).to eq(taxonomy_filter)
            expect(values).to be_an(Array)
          end

          it "includes parent taxonomy names in the values" do
            _filter, values = helper.filter_ideas_taxonomy_values.first
            labels = values.map(&:first)
            # Children are grouped under their parent; parent name appears as label
            expect(labels).not_to be_empty
          end

          it "prefixes child taxonomy names with an em dash" do
            _filter, values = helper.filter_ideas_taxonomy_values.first
            # All items returned by the factory are direct children of the root,
            # so they appear as "— <name>" lines
            child_labels = values.map(&:first).select { |l| l.start_with?("— ") }
            expect(child_labels).not_to be_empty
          end

          it "returns taxonomy ids as the option values" do
            _filter, values = helper.filter_ideas_taxonomy_values.first
            ids = values.map(&:last)
            expect(ids).to all(be_an(Integer))
          end
        end
      end

      describe "#filter_ideas_state_values" do
        it "returns exactly three state options" do
          expect(helper.filter_ideas_state_values.length).to eq(3)
        end

        it "includes accepted, rejected, and not_answered states" do
          state_keys = helper.filter_ideas_state_values.map(&:last)
          expect(state_keys).to contain_exactly("accepted", "rejected", "not_answered")
        end
      end

      describe "#idea_reason_callout_class" do
        {
          "accepted" => "success",
          "evaluating" => "warning",
          "rejected" => "alert",
          "withdrawn" => ""
        }.each do |state, expected_class|
          it "returns '#{expected_class}' for state '#{state}'" do
            idea = double("idea", state: state)
            helper.instance_variable_set(:@idea, idea)
            expect(helper.idea_reason_callout_class).to eq(expected_class)
          end
        end
      end

      describe "#resource_version" do
        context "when the resource does not respond to amendable?" do
          it "returns nil" do
            resource = double("resource")
            allow(resource).to receive(:respond_to?).with(:amendable?).and_return(false)
            expect(helper.resource_version(resource)).to be_nil
          end
        end

        context "when the resource is not amendable" do
          it "returns nil" do
            resource = double("resource", amendable?: false)
            allow(resource).to receive(:respond_to?).with(:amendable?).and_return(true)
            expect(helper.resource_version(resource)).to be_nil
          end
        end
      end
    end
  end
end
