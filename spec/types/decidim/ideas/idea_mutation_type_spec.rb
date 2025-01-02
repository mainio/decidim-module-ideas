# frozen_string_literal: true

require "spec_helper"
require "decidim/api/test/type_context"

describe Decidim::Ideas::IdeaMutationType, type: :graphql do
  include_context "with a graphql class type"
  let!(:component) { create(:idea_component, :with_creation_enabled, participatory_space:) }
  let!(:participatory_space) { create(:participatory_process, :with_steps, organization: current_organization) }
  let(:author) { create(:user, :admin, :confirmed, organization: current_organization) }
  let(:attributes) do
    {
      title: generate(:title).dup
    }
  end
  let(:model) { create(:idea, attributes.merge(component:, users: [author])) }

  describe "id" do
    let(:query) { "{ id }" }

    it "returns the idea's id" do
      expect(response["id"]).to eq(model.id.to_s)
    end
  end

  describe "answer" do
    let(:query) { '{ answer(state: "accepted") { state id } }' }
    let(:model) { create(:idea, :with_answer, attributes.merge(component:, users: [author])) }
    let(:state) { "accepted" }

    it "raises error for unauthorized user" do
      expect { response }.to raise_error(Decidim::Ideas::ActionForbidden)
    end

    context "when authorized" do
      before do
        allow_any_instance_of(Decidim::Ideas::IdeaMutationType).to receive(:allowed_to?).and_return(true) # rubocop:disable RSpec/AnyInstance
      end

      it "returns the idea's answer" do
        answer = response["answer"]
        expect(answer).to include("state" => "accepted")
        expect(answer).to include("id" => model.id.to_s)
      end
    end
  end
end
