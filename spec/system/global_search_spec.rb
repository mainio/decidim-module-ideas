# frozen_string_literal: true

require "spec_helper"

describe "global search", type: :system do
  include_context "with a component"

  let(:component) { create(:idea_component, organization: organization) }
  let!(:idea) { create(:idea, component: component, title: idea_title) }
  let!(:idea2) { create(:idea, component: component, title: idea2_title) }
  let(:idea_title) { ::Faker::Lorem.sentence }
  let(:idea2_title) { ::Faker::Hipster.sentence }

  before do
    visit "/"
  end

  it "finds idea" do
    fill_in :term, with: idea.title
    click_button "Search"
    expect(page).to have_content("1 RESULTS FOR THE SEARCH")
    expect(page).to have_content(idea_title)
    expect(page).not_to have_content(idea2_title)
  end
end
