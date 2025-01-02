# frozen_string_literal: true

require "spec_helper"

describe "GlobalSearch" do
  include_context "with a component"

  let(:component) { create(:idea_component, organization:) }
  let!(:idea) { create(:idea, component:, title: idea_title) }
  let!(:second_idea) { create(:idea, component:, title: second_idea_title) }
  let(:idea_title) { Faker::Lorem.sentence }
  let(:second_idea_title) { Faker::Hipster.sentence }

  before do
    visit "/"
  end

  it "finds idea" do
    within ".main-bar__search" do
      fill_in :term, with: idea.title
    end

    find("input#input-search").native.send_keys :enter
    expect(page).to have_content("1 Results for the search")
    expect(page).to have_content(idea_title)
    expect(page).to have_no_content(second_idea_title)
  end
end
