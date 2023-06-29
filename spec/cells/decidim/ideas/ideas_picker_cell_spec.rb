# frozen_string_literal: true

require "spec_helper"

describe Decidim::Ideas::IdeasPickerCell, type: :cell do
  controller Decidim::Ideas::IdeasController

  subject { my_cell.call }

  let(:my_cell) { cell("decidim/ideas/ideas_picker", component) }
  let(:organization) { create(:organization, tos_version: Time.current) }
  let(:participatory_space) { create(:participatory_process, :with_steps, organization: organization) }
  let(:component) { create(:idea_component, participatory_space: participatory_space) }
  let!(:ideas) { create_list(:idea, 30, :accepted, component: component) }
  let!(:unanswered_ideas) { create_list(:idea, 30, component: component) }

  let(:another_space) { create(:participatory_process, :with_steps, organization: organization) }
  let(:another_component) { create(:idea_component, participatory_space: another_space) }
  let!(:external_idea) { create(:idea, :accepted, component: another_component) }

  it "renders accepted ideas" do
    ideas.each do |idea|
      expect(subject).to have_content(translated(idea.title))
    end
  end

  it "does not render unanswered ideas" do
    unanswered_ideas.each do |idea|
      expect(subject).not_to have_content(translated(idea.title))
    end
  end

  it "does not render ideas from other components" do
    expect(subject).not_to have_content(translated(external_idea.title))
  end
end
