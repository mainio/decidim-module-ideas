# frozen_string_literal: true

require "spec_helper"

describe Decidim::Ideas::HighlightedIdeasCell, type: :cell do
  controller Decidim::Ideas::IdeasController

  subject { my_cell.call }

  let(:my_cell) { cell("decidim/ideas/highlighted_ideas", participatory_space) }
  let(:organization) { create(:organization, tos_version: Time.current) }
  let(:participatory_space) { create(:participatory_process, :with_steps, organization: organization) }
  let(:component_1) { create(:idea_component, participatory_space: participatory_space) }
  let(:component_2) { create(:idea_component, participatory_space: participatory_space) }
  let!(:idea_1) { create(:idea, component: component_1) }
  let!(:idea_2) { create(:idea, component: component_2) }

  let(:another_space) { create(:participatory_process, :with_steps, organization: organization) }
  let(:another_component) { create(:idea_component, participatory_space: another_space) }
  let!(:external_idea) { create(:idea, component: another_component) }

  it "renders the ideas from components under the same space" do
    expect(subject).to have_css(".card.card--idea", count: 2)
    expect(subject).to have_content(translated(idea_1.title))
    expect(subject).to have_content(translated(idea_2.title))
    expect(subject).not_to have_content(translated(external_idea.title))
  end
end
