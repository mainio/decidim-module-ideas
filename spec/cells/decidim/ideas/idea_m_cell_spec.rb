# frozen_string_literal: true

require "spec_helper"

module Decidim::Ideas
  describe IdeaMCell, type: :cell do
    controller Decidim::Ideas::IdeasController

    subject { cell_html }

    let(:my_cell) { cell("decidim/ideas/idea_m", idea, context: { show_space: show_space }) }
    let(:cell_html) { my_cell.call }
    let(:created_at) { Time.current - 1.month }
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

    it_behaves_like "has space in m-cell"

    context "when rendering" do
      let(:show_space) { false }

      it "renders the card" do
        expect(subject).to have_css(".card--idea")
      end

      it "renders the published_at date" do
        published_date = I18n.l(published_at.to_date, format: :decidim_short)
        creation_date = I18n.l(created_at.to_date, format: :decidim_short)

        expect(subject).to have_css(".creation_date_status", text: published_date)
        expect(subject).not_to have_css(".creation_date_status", text: creation_date)
      end

      # context "and is a idea" do
      #   it "renders the idea state (nil by default)" do
      #     expect(subject).to have_css(".muted")
      #     expect(subject).not_to have_css(".card__text--status")
      #   end
      # end

      # context "and is an emendation" do
      #   subject { cell_html }

      #   let(:my_cell) { cell("decidim/ideas/idea_m", emendation, context: { show_space: show_space }) }
      #   let(:cell_html) { my_cell.call }

      #   it "renders the emendation state (evaluating by default)" do
      #     expect(subject).to have_css(".warning")
      #     expect(subject).to have_css(".card__text--status", text: emendation.state.capitalize)
      #   end
      # end

      context "when it is a idea preview" do
        subject { cell_html }

        let(:my_cell) { cell("decidim/ideas/idea_m", model, preview: true) }
        let(:cell_html) { my_cell.call }

        it "renders the card with no status info" do
          expect(subject).to have_css(".card__header")
          expect(subject).to have_css(".card__text")
          expect(subject).to have_no_css(".card-data__item")
        end
      end

      # context "and has an image attachment" do
      #   let!(:attachment_1_pdf) { create(:attachment, :with_pdf, attached_to: idea) }
      #   let!(:attachment_2_img) { create(:attachment, :with_image, attached_to: idea) }
      #   let!(:attachment_3_pdf) { create(:attachment, :with_pdf, attached_to: idea) }
      #   let!(:attachment_4_img) { create(:attachment, :with_image, attached_to: idea) }

      #   it "renders the first image in the card whatever the order between attachments" do
      #     expect(subject).to have_css(".card__image")
      #     expect(subject).to have_css("img[src=\"#{attachment_2_img.url}\"]")
      #   end
      # end
    end
  end
end
