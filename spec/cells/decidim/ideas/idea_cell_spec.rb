# frozen_string_literal: true

require "spec_helper"

describe Decidim::Ideas::IdeaCell, type: :cell do
  controller Decidim::Ideas::IdeasController

  subject { my_cell.call }

  let(:my_cell) { cell("decidim/ideas/idea", model) }
  let!(:idea) { create(:idea, component: component) }
  let!(:current_user) { create(:user, :confirmed, organization: model.participatory_space.organization) }
  let!(:category) { create(:category, participatory_space: component.participatory_space) }
  let!(:scope) { create(:scope, organization: component.participatory_space.organization) }
  let(:component) { create(:idea_component) }

  before do
    idea.update(category: category)
    idea.update(area_scope: scope)
    allow(controller).to receive(:current_user).and_return(current_user)
  end

  context "when rendering a user idea" do
    let(:model) { idea }

    it "renders the card" do
      expect(subject).to have_css(".card--idea")
    end
  end
end
