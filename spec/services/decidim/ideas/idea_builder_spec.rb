# frozen_string_literal: true

require "spec_helper"

describe Decidim::Ideas::IdeaBuilder do
  let(:attributes) do
    {
      title: "Idea title",
      body: "Idea body",
      category: category,
      area_scope: area_scope,
      component: component,
      address: "Veneentekijäntie 4",
      latitude: 1.234,
      longitude: 2.345,
      published_at: Time.current
    }
  end
  let(:organization) { component.organization }
  let(:area_scope_parent) { create(:area_scope_parent, organization: organization) }
  let(:area_scope) { area_scope_parent.children.sample }
  let(:component) { create(:idea_component) }
  let(:category) { create(:category, participatory_space: component.participatory_space) }
  let(:author) { create(:user, :confirmed, organization: organization) }
  let(:action_user) { author }
  let(:user_group_author) { nil }

  describe "#create" do
    subject { described_class.create(attributes: attributes, author: author, action_user: action_user, user_group_author: user_group_author) }

    it "creates a new idea" do
      expect(subject).to be_a(Decidim::Ideas::Idea)
      expect(subject.authors.first).to eq(author)
      expect(subject.title).to eq(attributes[:title])
      expect(subject.body).to eq(attributes[:body])
      expect(subject.category).to eq(attributes[:category])
      expect(subject.area_scope).to eq(attributes[:area_scope])
      expect(subject.address).to eq(attributes[:address])
      expect(subject.latitude).to eq(attributes[:latitude])
      expect(subject.longitude).to eq(attributes[:longitude])
      expect(subject.published_at).to eq(attributes[:published_at])
    end
  end

  describe "#copy" do
    subject { described_class.copy(original_idea, author: author, action_user: action_user, user_group_author: user_group_author) }

    let(:original_idea) { create(:idea, **attributes) }

    it "copies the idea" do
      expect(subject).to be_a(Decidim::Ideas::Idea)
      expect(subject).not_to eq(original_idea)
      expect(subject.authors.first).to eq(author)
      expect(subject.title).to eq(attributes[:title])
      expect(subject.body).to eq(attributes[:body])
      expect(subject.category).to eq(attributes[:category])
      expect(subject.area_scope).to eq(attributes[:area_scope])
      expect(subject.address).to eq(attributes[:address])
      expect(subject.latitude).to eq(attributes[:latitude])
      expect(subject.longitude).to eq(attributes[:longitude])
      expect(subject.published_at).to eq(attributes[:published_at])
    end

    context "without author" do
      let(:original_idea) { create(:idea, users: [original_author], **attributes) }
      let(:author) { nil }
      let(:original_author) { create(:user, :confirmed, organization: organization) }

      it "copies the idea with authors" do
        expect(subject).to be_a(Decidim::Ideas::Idea)
        expect(subject).not_to eq(original_idea)
        expect(subject.authors.first).to eq(original_author)
        expect(subject.title).to eq(attributes[:title])
        expect(subject.body).to eq(attributes[:body])
        expect(subject.category).to eq(attributes[:category])
        expect(subject.area_scope).to eq(attributes[:area_scope])
        expect(subject.address).to eq(attributes[:address])
        expect(subject.latitude).to eq(attributes[:latitude])
        expect(subject.longitude).to eq(attributes[:longitude])
        expect(subject.published_at).to eq(attributes[:published_at])
      end
    end
  end
end
