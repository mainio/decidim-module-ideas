# frozen_string_literal: true

require "spec_helper"

describe Decidim::Ideas::AmendIdea do
  subject { command.call }

  let(:command) { described_class.new(form, user, idea) }
  let!(:idea) { create(:idea, component: component, users: [user]) }
  let(:form) { Decidim::Ideas::IdeaForm.new(idea_data) }
  let(:idea_data) do
    {
      title: "A new testing idea",
      body: "This is the body of the idea.",
      terms_agreed: true,
      address: "Foostreet 123",
      latitude: 1.123,
      longitude: 2.345,
      perform_geocoding: false,
      category_id: category.id,
      area_scope_id: area_scope.id
    }
  end
  let(:organization) { create(:organization) }
  let(:participatory_space) { create(:participatory_process, :with_steps, organization: organization) }
  let(:component) { create(:idea_component, participatory_space: participatory_space) }
  let(:category) { create(:category, participatory_space: participatory_space) }
  let(:area_scope) { create(:scope, organization: organization) }
  let(:user) { create(:user, :admin, organization: organization) }

  before do
    allow(form).to receive(:current_organization).and_return(organization)
    allow(form).to receive(:current_component).and_return(component)
    allow(form).to receive(:component).and_return(component)
    allow(form).to receive(:current_user).and_return(user)
  end

  it "broadcasts ok" do
    expect { subject }.to broadcast(:ok)
  end

  it "amends the idea" do
    expect { subject }.to change(Decidim::Ideas::Idea, :count).by(1)

    idea.reload
    expect(idea.title).to eq(idea_data[:title])
    expect(idea.body).to eq(idea_data[:body])
    expect(idea.address).to eq(idea_data[:address])
    expect(idea.latitude).to eq(idea_data[:latitude])
    expect(idea.longitude).to eq(idea_data[:longitude])
    expect(idea.category.id).to eq(idea_data[:category_id])
    expect(idea.area_scope.id).to eq(idea_data[:area_scope_id])
  end
end
