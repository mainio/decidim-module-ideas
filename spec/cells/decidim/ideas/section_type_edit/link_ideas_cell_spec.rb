# frozen_string_literal: true

require "spec_helper"

describe Decidim::Ideas::SectionTypeEdit::LinkIdeasCell, type: :cell do
  include ActionView::Helpers::SanitizeHelper

  controller Decidim::LastActivitiesController

  subject { my_cell.call }

  let(:my_cell) do
    cell(
      "decidim/ideas/section_type_edit/link_ideas",
      content,
      multilingual_answers: false,
      context: { form: form, parent_form: parent_form, current_component: component }
    )
  end

  let(:parent_form) { Decidim::FormBuilder.new(:plan, plan, template, {}) }
  let(:record) { Decidim::Ideas::ContentData::LinkIdeasForm.new(section_id: section.id, plan_id: plan.id, idea_ids: ideas.map(&:id)) }
  let(:form) { Decidim::FormBuilder.new("contents[#{section.id}]", record, template, model: content) }
  let(:template_class) do
    Class.new(ActionView::Base) do
      def protect_against_forgery?
        false
      end
    end
  end
  let(:template) { template_class.new(ActionView::LookupContext.new(ActionController::Base.view_paths), {}, controller) }

  let(:organization) { create(:organization, tos_version: Time.current) }
  let(:participatory_space) { create(:participatory_process, :with_steps, organization: organization) }
  let(:component) { create(:plan_component, participatory_space: participatory_space) }
  let(:section) { create(:section, section_type: "link_ideas", component: component) }
  let(:plan) { create(:plan, component: component) }
  let(:content) { create(:content, plan: plan, section: section, body: { idea_ids: ideas.map(&:id) }) }

  let(:idea_component) { create(:idea_component, participatory_space: participatory_space) }
  let(:ideas) { create_list(:idea, 3, :accepted, component: idea_component) }

  before do
    allow(controller).to receive(:current_participatory_space).and_return(participatory_space)
  end

  it "displays the linked ideas" do
    ideas.each do |idea|
      expect(subject).to have_content(strip_tags(translated(idea.title)))
    end
  end

  it "renders the link to attach a new idea" do
    expect(subject).to have_link("Attach idea")
  end
end
