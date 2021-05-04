# frozen_string_literal: true

require "spec_helper"

describe "show map", type: :system do
  include_context "with a component"

  let(:organization) { create(:organization) }
  let(:component) { create(:idea_component, :with_geocoding_enabled, organization: organization) }
  let!(:area_scope_parent) { create(:area_scope_parent, organization: organization) }
  let(:area_scope_child) { area_scope_parent.children.first }
  let(:area_scope_child2) { area_scope_parent.children.second }
  let(:area_scope_child3) { area_scope_parent.children.third }
  let(:area_scope_child4) { area_scope_parent.children.fourth }
  let(:area_scope_child5) { area_scope_parent.children.fifth }
  let!(:idea) { create(:idea, component: component) }

  let(:address) { "Fredrikinkatu, 3" }
  let(:latitude) { 60.192 }
  let(:longitude) { 24.945 }

  let(:coordinates) do
    {
      latitude: 60.192059,
      longitude: 24.945831
    }
  end

  before do
    stub_geocoding(address, [latitude, longitude])
    component[:settings]["global"]["area_scope_parent_id"] = area_scope_parent.id
    component.update!(
      settings: {
        area_scope_coordinates: {
          area_scope_child.id.to_s => "#{coordinates[:latitude]},#{coordinates[:longitude]}",
          area_scope_child2.id.to_s => "#{coordinates[:latitude] - 0.01},#{coordinates[:longitude] - 0.01}",
          area_scope_child3.id.to_s => "#{coordinates[:latitude] + 0.02},#{coordinates[:longitude] + 0.001}",
          area_scope_child4.id.to_s => "#{coordinates[:latitude] - 0.03},#{coordinates[:longitude] + 0.02}",
          area_scope_child5.id.to_s => "#{coordinates[:latitude] + 0.04},#{coordinates[:longitude] - 0.03}"
        },
        geocoding_enabled: true
      }
    )
    visit_component
  end

  describe "index" do
    it "shows map" do
      page.execute_script "window.scrollBy(0,500)"
      expect(page).to have_content("something that there definetly isnt")
    end
  end
end
