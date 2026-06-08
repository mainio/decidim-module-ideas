# frozen_string_literal: true

require "spec_helper"

describe Decidim::Ideas::CreateIdea do
  subject { command.call }

  let(:command) { described_class.new(form, user) }
  let(:form) { Decidim::Ideas::IdeaForm.new(idea_data) }
  let(:taxonomy_filter) { create(:idea_taxonomy_filter, organization:) }
  let(:taxonomy) { taxonomy_filter.root_taxonomy.children.first }
  let(:idea_data) do
    {
      title: "A new testing idea",
      body: "This is the body of the idea.",
      terms_agreed: true,
      address: "Foostreet 123",
      latitude: 1.123,
      longitude: 2.345,
      perform_geocoding: false,
      taxonomy_ids: [taxonomy.id]
    }
  end
  let(:organization) { create(:organization, tos_version: Time.current) }
  let(:participatory_space) { create(:participatory_process, :with_steps, organization:) }
  let(:idea_limit) { 0 }
  let(:component) { create(:idea_component, :with_idea_limit, idea_limit:, participatory_space:) }
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

  context "with idea limit" do
    let!(:idea) { create(:idea, :accepted, component:, users: [user], category: false, area_scope: false) }

    context "when limitation reached" do
      let(:idea_limit) { 1 }

      it "broadcasts invalid" do
        expect { subject }.to broadcast(:invalid)
        expect(Decidim::Ideas::Idea.count).to eq(1)
        expect(form.errors.full_messages).to include("You can't create new ideas since you've exceeded the limit.")
      end

      context "when the idea was withdrawn" do
        let(:idea_limit) { 2 }
        let!(:idea) { create(:idea, :withdrawn, component:, users: [user], category: false, area_scope: false) }

        it "broadcasts ok" do
          expect { subject }.to broadcast(:ok)
        end
      end
    end

    context "when not reached the limit" do
      let(:idea_limit) { 2 }

      it "broadcasts ok" do
        expect { subject }.to broadcast(:ok)
      end
    end
  end

  context "with user group" do
    let(:idea_limit) { 1 }
    let!(:user) { create(:user_group, organization:) }
    let!(:idea) { create(:idea, :accepted, component:, users: [user], category: false, area_scope: false) }

    it "broadcasts invalid" do
      expect { subject }.to broadcast(:invalid)
      expect(Decidim::Ideas::Idea.count).to eq(1)
      expect(form.errors.full_messages).to include("You can't create new ideas since you've exceeded the limit.")
    end
  end
end