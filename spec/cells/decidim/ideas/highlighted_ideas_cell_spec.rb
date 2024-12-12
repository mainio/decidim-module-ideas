# frozen_string_literal: true

require "spec_helper"

describe Decidim::Ideas::HighlightedIdeasCell, type: :cell do
  controller Decidim::Ideas::IdeasController

  subject { my_cell.call }

  let(:my_cell) { cell("decidim/ideas/highlighted_ideas", participatory_space) }
  let(:organization) { create(:organization, tos_version: Time.current) }
  let(:participatory_space) { create(:participatory_process, :with_steps, organization: organization) }
  let(:component1) { create(:idea_component, participatory_space: participatory_space) }
  let(:component2) { create(:idea_component, participatory_space: participatory_space) }
  let!(:idea1) { create(:idea, component: component1) }
  let!(:idea2) { create(:idea, component: component2) }

  let(:another_space) { create(:participatory_process, :with_steps, organization: organization) }
  let(:another_component) { create(:idea_component, participatory_space: another_space) }
  let!(:external_idea) { create(:idea, component: another_component) }

  it "renders the ideas from components under the same space" do
    expect(subject).to have_css(".card__content", count: 2)
    expect(subject).to have_content(translated(idea1.title))
    expect(subject).to have_content(translated(idea2.title))
    expect(subject).not_to have_content(translated(external_idea.title))
  end
end
