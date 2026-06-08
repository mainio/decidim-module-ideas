# frozen_string_literal: true

require "spec_helper"

describe Decidim::Ideas::Admin::CreateIdea do
  subject { command.call }

  let(:command) { described_class.new(form, user) }
  let(:form) { Decidim::Ideas::Admin::IdeaForm.new(idea_data) }
  let(:taxonomy_filter) { create(:idea_taxonomy_filter, organization:) }
  let(:taxonomy) { taxonomy_filter.root_taxonomy.children.first }
  let(:idea_data) do
    {
      title: "A new testing idea",
      body: "This is the body of the idea.",
      address: "Foostreet 123",
      latitude: 1.123,
      longitude: 2.345,
      perform_geocoding: false,
      taxonomy_ids: [taxonomy.id]
    }
  end
  let(:organization) { create(:organization, tos_version: Time.current) }
  let(:participatory_space) { create(:participatory_process, :with_steps, organization:) }
  let(:component) { create(:idea_component, participatory_space:) }
  let(:user) { create(:user, :confirmed, :admin, organization:) }

  before do
    allow(form).to receive(:current_organization).and_return(organization)
    allow(form).to receive(:current_component).and_return(component)
    allow(form).to receive(:component).and_return(component)
    allow(form).to receive(:current_user).and_return(user)
    allow(form).to receive(:taxonomizations).and_return(
      [Decidim::Taxonomization.new(taxonomy: taxonomy)]
    )
    allow(form).to receive(:area_scope).and_return(nil)
    allow(form).to receive(:category).and_return(nil)
  end

  it "broadcasts ok" do
    expect { subject }.to broadcast(:ok)
  end

  it "creates the idea" do
    expect { subject }.to change(Decidim::Ideas::Idea, :count).by(1)

    idea = Decidim::Ideas::Idea.last
    expect(idea.title).to eq(idea_data[:title])
    expect(idea.body).to eq(idea_data[:body])
    expect(idea.address).to eq(idea_data[:address])
    expect(idea.latitude).to eq(idea_data[:latitude])
    expect(idea.longitude).to eq(idea_data[:longitude])
    expect(idea.taxonomies).to include(taxonomy)
  end
end