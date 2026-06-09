# frozen_string_literal: true

require "spec_helper"

describe Decidim::Ideas::IdeasPickerCell, type: :cell do
  controller Decidim::Ideas::IdeasController

  subject { my_cell.call }

  let(:my_cell) { cell("decidim/ideas/ideas_picker", component) }
  let(:organization) { create(:organization, tos_version: Time.current) }
  let(:participatory_space) { create(:participatory_process, :with_steps, organization:) }
  let(:component) { create(:idea_component, participatory_space:) }
  let!(:ideas) { create_list(:idea, 10, :accepted, component:) }
  let!(:unanswered_ideas) { create_list(:idea, 10, component:) }

  let(:another_space) { create(:participatory_process, :with_steps, organization:) }
  let(:another_component) { create(:idea_component, participatory_space: another_space) }
  let!(:external_idea) { create(:idea, :accepted, component: another_component) }

  it "renders accepted ideas" do
    ideas.each do |idea|
      expect(subject).to have_content(translated(idea.title))
    end
  end

  it "does not render unanswered ideas" do
    unanswered_ideas.each do |idea|
      expect(subject).to have_no_content(translated(idea.title))
    end
  end

  it "does not render ideas from other components" do
    expect(subject).to have_no_content(translated(external_idea.title))
  end

  context "when filtering by text" do
    let(:my_cell) { cell("decidim/ideas/ideas_picker", component) }

    before do
      allow(controller).to receive(:params).and_return(
        ActionController::Parameters.new(q: translated(ideas.first.title))
      )
    end

    it "renders matching ideas" do
      expect(subject).to have_content(translated(ideas.first.title))
    end
  end

  context "when there are more than MAX_IDEAS ideas" do
    before do
      stub_const("Decidim::Ideas::IdeasPickerCell::MAX_IDEAS", 5)
    end

    it "renders a warning about more ideas" do
      expect(subject).to have_css(".callout.warning")
    end
  end

  context "when filtering by taxonomy" do
    let(:taxonomy_filter) { create(:idea_taxonomy_filter, organization:) }
    let(:taxonomy) { taxonomy_filter.root_taxonomy.children.first }
    let!(:taxonomy_ideas) { create_list(:idea, 3, :accepted, component:, category: false, area_scope: false, taxonomies: [taxonomy]) }

    before do
      allow(controller).to receive(:params).and_return(
        ActionController::Parameters.new("with_taxonomy_filter_#{taxonomy_filter.id}" => [taxonomy.id.to_s])
      )
    end

    it "renders only ideas with matching taxonomy" do
      taxonomy_ideas.each do |idea|
        expect(subject).to have_content(translated(idea.title))
      end
    end
  end
end
