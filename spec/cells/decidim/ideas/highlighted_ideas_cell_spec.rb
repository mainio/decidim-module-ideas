# frozen_string_literal: true

require "spec_helper"

describe Decidim::Ideas::HighlightedIdeasCell, type: :cell do
  controller Decidim::Ideas::IdeasController

  subject { my_cell.call }

  let(:my_cell) { cell("decidim/ideas/highlighted_ideas", participatory_space) }
  let(:organization) { create(:organization, tos_version: Time.current) }
  let(:participatory_space) { create(:participatory_process, :with_steps, organization:) }
  let(:first_component) { create(:idea_component, participatory_space:) }
  let(:second_component) { create(:idea_component, participatory_space:) }
  let!(:first_idea) { create(:idea, component: first_component) }
  let!(:second_idea) { create(:idea, component: second_component) }

  let(:another_space) { create(:participatory_process, :with_steps, organization:) }
  let(:another_component) { create(:idea_component, participatory_space: another_space) }
  let!(:external_idea) { create(:idea, component: another_component) }

  it "renders the ideas from components under the same space" do
    expect(subject).to have_css(".card__content", count: 2)
    expect(subject).to have_content(translated(first_idea.title))
    expect(subject).to have_content(translated(second_idea.title))
    expect(subject).to have_no_content(translated(external_idea.title))
  end
end
