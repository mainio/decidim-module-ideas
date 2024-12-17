# frozen_string_literal: true

require "spec_helper"

module Decidim::Ideas
  describe IdeaGCell, type: :cell do
    controller Decidim::Ideas::IdeasController

    subject { cell_html }

    let(:my_cell) { cell("decidim/ideas/idea_g", idea, context: { show_space: }) }
    let(:cell_html) { my_cell.call }
    let(:created_at) { 1.month.ago }
    let(:published_at) { Time.current }
    let(:component) { create(:idea_component, :with_attachments_allowed, :with_card_image_allowed) }
    let!(:idea) { create(:idea, component: component, created_at: created_at, published_at: published_at) }
    let(:model) { idea }
    let(:user) { create :user, organization: idea.participatory_space.organization }
    let!(:emendation) { create(:idea) }
    let!(:amendment) { create :amendment, amendable: idea, emendation: emendation }
    let!(:category) { create(:category, participatory_space: component.participatory_space) }
    let!(:scope) { create(:scope, organization: component.participatory_space.organization) }

    before do
      idea.update(category: category)
      idea.update(area_scope: scope)
      allow(controller).to receive(:current_user).and_return(user)
    end

    context "when rendering with show_space flag" do
      let(:show_space) { true }

      it "renders the space where the model belongs to" do
        expect(subject).to have_content(translated_attribute(model.component.participatory_space.title))
      end
    end

    context "when rendering" do
      let(:show_space) { false }

      it "renders the card" do
        expect(subject).to have_css(".card__content")
      end

      it "renders the published_at date" do
        published_date = I18n.l(published_at.to_date, format: :decidim_short)
        creation_date = I18n.l(created_at.to_date, format: :decidim_short)

        expect(subject).to have_css(".card__info__item", text: published_date)
        expect(subject).not_to have_css(".card__status", text: creation_date)
      end

      context "when it is a idea preview" do
        subject { cell_html }

        let(:my_cell) { cell("decidim/ideas/idea_g", model, preview: true) }
        let(:cell_html) { my_cell.call }

        it "renders the card with no status info" do
          expect(subject).to have_css(".card__content")
          expect(subject).to have_css(".card__text")
          expect(subject).to have_no_css(".card-data__item")
        end
      end
    end
  end
end
