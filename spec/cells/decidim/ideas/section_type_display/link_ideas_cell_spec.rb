# frozen_string_literal: true

require "spec_helper"

describe Decidim::Ideas::SectionTypeDisplay::LinkIdeasCell, type: :cell do
  include ActionView::Helpers::SanitizeHelper

  controller Decidim::LastActivitiesController

  subject { my_cell.call }

  let(:my_cell) { cell("decidim/ideas/section_type_display/link_ideas", content) }

  let(:organization) { create(:organization) }
  let(:participatory_space) { create(:participatory_process, :with_steps, organization: organization) }
  let(:component) { create(:plan_component, participatory_space: participatory_space) }
  let(:section) { create(:section, section_type: "link_ideas", component: component) }
  let(:plan) { create(:plan, component: component) }
  let(:content) { create(:content, plan: plan, section: section, body: { idea_ids: ideas.map(&:id) }) }

  let(:idea_component) { create(:idea_component, participatory_space: participatory_space) }
  let(:ideas) { create_list(:idea, 3, :accepted, component: idea_component) }

  it "displays the linked ideas" do
    ideas.each do |idea|
      expect(subject).to have_content(strip_tags(translated(idea.title)))
    end
  end
end
