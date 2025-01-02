# frozen_string_literal: true

require "spec_helper"

describe Decidim::Ideas::InfoController do
  routes { Decidim::Ideas::Engine.routes }

  let(:organization) { component.organization }
  let(:component) { create(:idea_component, settings:) }
  let(:settings) { {} }

  before do
    request.env["decidim.current_organization"] = organization
    request.env["decidim.current_participatory_space"] = component.participatory_space
    request.env["decidim.current_component"] = component
  end

  describe "GET show" do
    shared_examples "section content as JSON" do
      subject { response.parsed_body }

      it "returns the correct text" do
        get :show, format: :json, params: { section: }
        expect(response).to have_http_status(:ok)
        expect(response.headers["X-Robots-Tag"]).to eq("none")
        expect(subject).to eq(
          "intro" => settings["#{section_key}_intro".to_sym].values.first,
          "text" => settings["#{section_key}_text".to_sym].values.first
        )
      end
    end

    context "with the terms section" do
      let(:section) { "terms" }
      let(:section_key) { section }
      let(:settings) { { terms_intro: { en: "Intro" }, terms_text: { en: "Text" } } }

      it_behaves_like "section content as JSON"
    end

    context "with the areas section" do
      let(:section) { "areas" }
      let(:section_key) { "areas_info" }
      let(:settings) { { areas_info_intro: { en: "Intro" }, areas_info_text: { en: "Text" } } }

      it_behaves_like "section content as JSON"
    end

    context "with the categories section" do
      let(:section) { "categories" }
      let(:section_key) { "categories_info" }
      let(:settings) { { categories_info_intro: { en: "Intro" }, categories_info_text: { en: "Text" } } }

      it_behaves_like "section content as JSON"
    end

    context "with an unknown section" do
      let(:section) { "foobar" }

      it "shows a 404" do
        expect do
          get :show, format: :json, params: { section: }
        end.to raise_error(ActionController::RoutingError)
      end
    end
  end
end
