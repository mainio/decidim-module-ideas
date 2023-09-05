# frozen_string_literal: true

require "spec_helper"
require "decidim/api/test/type_context"

describe Decidim::Ideas::IdeaType, type: :graphql do
  include_context "with a graphql class type"

  let!(:component) { create(:idea_component, :with_creation_enabled, participatory_space: participatory_space) }
  let!(:participatory_space) { create :participatory_process, :with_steps, organization: current_organization }
  let(:author) { create :user, :confirmed, organization: current_organization }
  let(:attributes) do
    {
      title: generate(:title).dup
    }
  end
  let(:model) { create(:idea, attributes.merge(component: component, users: [author])) }

  describe "id" do
    let(:query) { "{ id }" }

    it "returns the idea's id" do
      expect(response["id"]).to eq(model.id.to_s)
    end
  end

  describe "coordinates" do
    let(:query) { "{ coordinates { latitude longitude } }" }
    let(:model) { create(:idea, :geocoded, attributes.merge(component: component, users: [author])) }

    it "returns the idea's coordinates" do
      expect(response["coordinates"]).to eq({ "latitude" => model.latitude, "longitude" => model.longitude })
    end

    context "when the idea does not have coordinates" do
      let(:model) { create(:idea, attributes.merge(component: component, users: [author])) }

      it "returns the idea's coordinates" do
        expect(response["coordinates"]).to be_nil
      end
    end
  end

  describe "linkingResources" do
    let(:query) { "{ linkingResources { __typename ...on Project { id } } }" }

    let(:budgets_component) { create(:budgets_component, participatory_space: participatory_space) }
    let(:project) { create(:project, budget: create(:budget, component: budgets_component)) }

    before do
      project.link_resources([model], "included_ideas")
    end

    it "returns the linking resource's id" do
      expect(response["linkingResources"]).to be_a(Array)
      expect(response["linkingResources"].count).to eq(1)

      resource = response["linkingResources"].first
      expect(resource["__typename"]).to eq("Project")
      expect(resource["id"]).to eq(project.id.to_s)
    end
  end
end
