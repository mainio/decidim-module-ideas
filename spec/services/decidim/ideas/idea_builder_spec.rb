# frozen_string_literal: true

require "spec_helper"

describe Decidim::Ideas::IdeaBuilder do
  let(:taxonomy_filter) { create(:idea_taxonomy_filter, organization:) }
  let(:taxonomy) { taxonomy_filter.root_taxonomy.children.first }
  let(:attributes) do
    {
      title: "Idea title",
      body: "Idea body",
      component:,
      address: "Veneentekijäntie 4",
      latitude: 1.234,
      longitude: 2.345,
      published_at: Time.current
    }
  end
  let(:organization) { component.organization }
  let(:component) { create(:idea_component) }
  let(:author) { create(:user, :confirmed, organization:) }
  let(:action_user) { author }
  let(:user_group_author) { nil }

  describe "#create" do
    subject { described_class.create(attributes:, author:, action_user:, user_group_author:) }

    it "creates a new idea" do
      expect(subject).to be_a(Decidim::Ideas::Idea)
      expect(subject.authors.first).to eq(author)
      expect(subject.title).to eq(attributes[:title])
      expect(subject.body).to eq(attributes[:body])
      expect(subject.address).to eq(attributes[:address])
      expect(subject.latitude).to eq(attributes[:latitude])
      expect(subject.longitude).to eq(attributes[:longitude])
      expect(subject.published_at).to eq(attributes[:published_at])
    end
  end

  describe "#copy" do
    subject { described_class.copy(original_idea, author:, action_user:, user_group_author:) }

    let(:original_idea) { create(:idea, **attributes, category: false, area_scope: false, taxonomies: [taxonomy]) }

    it "copies the idea" do
      expect(subject).to be_a(Decidim::Ideas::Idea)
      expect(subject).not_to eq(original_idea)
      expect(subject.authors.first).to eq(author)
      expect(subject.title).to eq(attributes[:title])
      expect(subject.body).to eq(attributes[:body])
      expect(subject.address).to eq(attributes[:address])
      expect(subject.latitude).to eq(attributes[:latitude])
      expect(subject.longitude).to eq(attributes[:longitude])
      expect(subject.published_at).to be_within(1.second).of(attributes[:published_at])
      expect(subject.reload.taxonomies).to include(taxonomy)
    end

    context "without author" do
      let(:original_idea) { create(:idea, users: [original_author], **attributes, category: false, area_scope: false, taxonomies: [taxonomy]) }
      let(:author) { nil }
      let(:original_author) { create(:user, :confirmed, organization:) }

      it "copies the idea with authors" do
        expect(subject).to be_a(Decidim::Ideas::Idea)
        expect(subject).not_to eq(original_idea)
        expect(subject.authors.first).to eq(original_author)
        expect(subject.title).to eq(attributes[:title])
        expect(subject.body).to eq(attributes[:body])
        expect(subject.address).to eq(attributes[:address])
        expect(subject.latitude).to eq(attributes[:latitude])
        expect(subject.longitude).to eq(attributes[:longitude])
        expect(subject.published_at).to be_within(1.second).of(attributes[:published_at])
        expect(subject.reload.taxonomies).to include(taxonomy)
      end
    end
  end
end