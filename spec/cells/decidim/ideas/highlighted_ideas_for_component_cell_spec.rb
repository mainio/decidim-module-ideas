# frozen_string_literal: true

require "spec_helper"

describe Decidim::Ideas::HighlightedIdeasForComponentCell, type: :cell do
  controller Decidim::Ideas::IdeasController

  subject { my_cell.call }

  let(:my_cell) { cell("decidim/ideas/highlighted_ideas_for_component", component) }
  let(:organization) { participatory_space.organization }
  let(:participatory_space) { component.participatory_space }
  let(:component) { create(:idea_component) }
  let!(:first_idea) { create(:idea, component:) }
  let!(:idea2) { create(:idea, component:) }
  let!(:unpublished_idea) { create(:idea, :unpublished, component:) }
  let!(:withdrawn_idea) { create(:idea, :withdrawn, component:) }
  let!(:hidden_idea) { create(:idea, :hidden, component:) }

  it "renders only the visible ideas" do
    expect(subject).to have_css(".card__content", count: 2)
    expect(subject).to have_content(translated(first_idea.title))
    expect(subject).to have_content(translated(idea2.title))
    expect(subject).to have_no_content(translated(unpublished_idea.title))
    expect(subject).to have_no_content(translated(withdrawn_idea.title))
    expect(subject).to have_no_content(translated(hidden_idea.title))
  end

  context "with a lot of ideas" do
    let!(:rest_of_ideas) { create_list(:idea, 10, component:) }

    it "shows the configured amount of ideas" do
      expect(subject).to have_css(".card__content", count: 4)
    end

    context "when the configuration is changed to a custom amount" do
      let(:amount) { 6 }

      before do
        allow(Decidim::Ideas.config).to receive(:participatory_space_highlighted_ideas_limit).and_return(amount)
      end

      it "shows the configured amount of ideas" do
        expect(subject).to have_css(".card__content", count: amount)
      end
    end
  end
end
