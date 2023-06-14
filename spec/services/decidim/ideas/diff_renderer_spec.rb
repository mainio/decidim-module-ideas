# frozen_string_literal: true

require "spec_helper"

describe Decidim::Ideas::DiffRenderer, versioning: true do
  let!(:idea) { create(:idea, area_scope_parent: area_scope_parent, component: component) }
  let!(:old_values) { idea.attributes }
  let!(:old_category) { idea.category }
  let!(:old_area_scope) { idea.area_scope }
  let(:version) { idea.versions.last }
  let(:component) { create(:idea_component) }
  let(:category) { create(:category, participatory_space: component.participatory_space) }
  let(:area_scope_parent) { create(:area_scope_parent, organization: component.organization) }
  let(:area_scope) { create(:scope, parent: area_scope_parent, organization: component.organization) }

  before do
    Decidim.traceability.update!(
      idea,
      idea.authors.first,
      title: "Updated idea title",
      body: "New idea test body",
      address: "Veneentekijäntie 4",
      latitude: 1.234,
      longitude: 2.345,
      category: category,
      area_scope: area_scope
    )
  end

  describe "#diff" do
    subject { described_class.new(version).diff }

    it "calculates the fields that have changed" do
      expect(subject.keys)
        .to contain_exactly(:title, :body, :address, :latitude, :longitude, :category_id, :area_scope_id)
    end

    it "has the old and new values for each field" do
      expect(subject[:title][:old_value]).to eq(old_values["title"])
      expect(subject[:title][:new_value]).to eq("Updated idea title")

      expect(subject[:body][:old_value]).to eq(old_values["body"])
      expect(subject[:body][:new_value]).to eq("New idea test body")

      expect(subject[:address][:old_value]).to eq(old_values["address"])
      expect(subject[:address][:new_value]).to eq("Veneentekijäntie 4")

      expect(subject[:latitude][:old_value]).to eq(old_values["latitude"])
      expect(subject[:latitude][:new_value]).to eq(1.234)
      expect(subject[:longitude][:old_value]).to eq(old_values["longitude"])
      expect(subject[:longitude][:new_value]).to eq(2.345)

      expect(subject[:category_id][:old_value]).to eq(translated(old_category.name))
      expect(subject[:category_id][:new_value]).to eq(translated(category.name))

      expect(subject[:area_scope_id][:old_value]).to eq(translated(old_area_scope.name))
      expect(subject[:area_scope_id][:new_value]).to eq(translated(area_scope.name))
    end

    it "has the type of each field" do
      expected_types = {
        title: :string,
        body: :string,
        address: :string,
        latitude: :string,
        longitude: :string,
        category_id: :category,
        area_scope_id: :scope
      }
      types = subject.to_h { |attribute, data| [attribute.to_sym, data[:type]] }
      expect(types).to eq expected_types
    end

    it "generates the labels correctly" do
      expected_labels = {
        title: "Idea title",
        body: "Idea description",
        address: "Add an optional neighbourhood for the idea or a more specific address",
        latitude: "Latitude",
        longitude: "Longitude",
        category_id: "Choose a theme for the idea",
        area_scope_id: "Choose an area for the idea"
      }
      labels = subject.to_h { |attribute, data| [attribute.to_sym, data[:label]] }
      expect(labels).to eq expected_labels
    end
  end
end
