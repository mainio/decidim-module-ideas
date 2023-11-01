# frozen_string_literal: true

require "spec_helper"

describe "map markers", type: :system do
  include_context "with a component"

  let(:organization) { create(:organization, tos_version: Time.current) }
  let(:component) { create(:idea_component, :with_geocoding_enabled, organization: organization) }
  let!(:area_scope_parent) { create(:area_scope_parent, organization: organization) }

  before do
    component[:settings]["global"]["area_scope_parent_id"] = area_scope_parent.id
  end

  context "when idea has coordinates" do
    let!(:idea_with_coordinates) do
      create(:idea,
             :geocoded,
             latitude: idea_latitude,
             longitude: idea_longitude,
             title: idea_with_coordinates_title,
             component: component)
    end
    let(:idea_with_coordinates_title) { ::Faker::Lorem.sentence }
    let(:idea_latitude) { 60.192059 }
    let(:idea_longitude) { 24.945831 }

    before do
      component.update!(
        settings: {
          geocoding_enabled: true
        }
      )
      visit_component
    end

    it "shows marker with idea's coordinates" do
      click_link "Show results on map"
      find_markers
      expect(page).to have_content("#{idea_with_coordinates_title}: #{idea_latitude}, #{idea_longitude}")
    end
  end

  context "with area scope with coordinates" do
    let!(:area_scope_child) { create(:scope, parent: area_scope_parent) }
    let!(:idea_with_area_scope) do
      create(:idea,
             title: idea_with_area_scope_title,
             component: component,
             area_scope: area_scope_child)
    end
    let(:idea_with_area_scope_title) { ::Faker::Hipster.sentence }
    let(:area_scope_latitude) { 60.1337 }
    let(:area_scope_longitude) { 25.1010 }

    before do
      component.update!(
        settings: {
          area_scope_coordinates: {
            area_scope_child.id.to_s => "#{area_scope_latitude},#{area_scope_longitude}"
          },
          geocoding_enabled: true
        }
      )
      visit_component
    end

    it "shows marker with area scope's coordinates" do
      click_link "Show results on map"
      find_markers
      expect(page).to have_content("#{idea_with_area_scope_title}: #{area_scope_latitude}, #{area_scope_longitude}")
    end
  end

  def find_markers
    expect(page).to have_selector("[data-decidim-map]", wait: 2)
    page.evaluate_script %{(function() {
      const $map = $("[data-decidim-map]").first();
      const ctrl = $map.data("map-controller");
      const layers = ctrl.markerClusters.getLayers();
      let $popup = null;
      layers.forEach((layer) => {
        $popup = $(layer.getPopup().getContent());
        const coordinates = layer.getLatLng();
        const text = $("h3", $popup).text()
        $("body").prepend(`${text}: ${coordinates.lat}, ${coordinates.lng}`)
      });
    })()}
  end
end
