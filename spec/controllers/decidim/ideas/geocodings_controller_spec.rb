# frozen_string_literal: true

require "spec_helper"

describe Decidim::Ideas::GeocodingsController do
  routes { Decidim::Ideas::Engine.routes }

  let(:user) { create(:user, :confirmed, organization:) }
  let(:organization) { component.organization }
  let(:component) { create(:idea_component, :with_creation_enabled) }
  let(:geocoder) { double }
  let(:geocoder_coordinates) { [1.234, 2.345] }
  let(:geocoder_address) { "Veneentekijäntie 4 A, 00210 Helsinki" }

  before do
    request.env["decidim.current_organization"] = organization
    request.env["decidim.current_participatory_space"] = component.participatory_space
    request.env["decidim.current_component"] = component
    sign_in user

    allow(Decidim::Map).to receive(:geocoding).with(organization:).and_return(geocoder)
    if geocoder
      allow(geocoder).to receive(:coordinates).and_return(geocoder_coordinates)
      allow(geocoder).to receive(:address).and_return(geocoder_address)
    end
  end

  describe "POST create" do
    context "when expecting a result" do
      subject { response.parsed_body }

      it "returns the correct coordinates" do
        get :create, params: { address: "Foobar" }
        expect(response).to have_http_status(:ok)
        expect(subject).to eq("success" => true, "result" => { "lat" => geocoder_coordinates[0], "lng" => geocoder_coordinates[1] })
      end
    end

    context "when idea creation is not enabled" do
      let(:component) { create(:idea_component) }

      it "redirects" do
        get :create, params: { address: "Foobar" }
        expect(response).to have_http_status(:redirect)
      end
    end

    context "when geocoder is not defined" do
      subject { response.parsed_body }

      let(:geocoder) { nil }

      it "returns a failure" do
        get :create, params: { address: "Foobar" }
        expect(subject).to eq("success" => false, "result" => {})
      end
    end
  end

  describe "POST reverse" do
    context "when expecting a result" do
      subject { response.parsed_body }

      it "returns the correct coordinates" do
        get :reverse, params: { lat: 1.123, lng: 2.345 }
        expect(response).to have_http_status(:ok)
        expect(subject).to eq("success" => true, "result" => { "address" => geocoder_address })
      end
    end

    context "when idea creation is not enabled" do
      let(:component) { create(:idea_component) }

      it "redirects" do
        get :reverse, params: { lat: 1.123, lng: 2.345 }
        expect(response).to have_http_status(:redirect)
      end
    end

    context "when geocoder is not defined" do
      subject { response.parsed_body }

      let(:geocoder) { nil }

      it "returns a failure" do
        get :create, params: { address: "Foobar" }
        expect(subject).to eq("success" => false, "result" => {})
      end
    end
  end
end
