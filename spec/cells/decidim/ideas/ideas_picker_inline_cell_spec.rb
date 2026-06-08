# frozen_string_literal: true

require "spec_helper"

describe Decidim::Ideas::IdeasPickerInlineCell, type: :cell do
  controller Decidim::Ideas::IdeasController

  subject { my_cell.call }

  let(:my_cell) { cell("decidim/ideas/ideas_picker_inline", component, context: { form: }) }
  let(:record) { OpenStruct.new(ideas: selected_ideas) }
  let(:form) { Decidim::FormBuilder.new(:record, record, template, {}) }
  let(:template_class) do
    Class.new(ActionView::Base) do
      def protect_against_forgery?
        false
      end
    end
  end
  let(:template) { template_class.new(ActionView::LookupContext.new(ActionController::Base.view_paths), {}, controller) }

  let(:participatory_space) { create(:participatory_process, :with_steps) }
  let(:component) { create(:idea_component, participatory_space:) }
  let!(:ideas) { create_list(:idea, 3, :accepted, component:, category: false, area_scope: false) }
  let(:selected_ideas) { [] }

  before do
    allow(controller).to receive(:current_participatory_space).and_return(participatory_space)
  end

  it "renders accepted ideas" do
    ideas.each do |idea|
      expect(subject).to have_css("[data-idea-id='#{idea.id}']")
    end
  end

  it "renders the inputs to select each idea" do
    ideas.each do |idea|
      expect(subject).to have_css("[data-idea-id='#{idea.id}']")
    end
  end

  context "when ideas are pre-selected" do
    let(:selected_ideas) { [ideas.first] }

    it "renders the pre-selected idea" do
      expect(subject).to have_css("[data-idea-id='#{ideas.first.id}']")
    end
  end

  context "when there are more than max ideas" do
    before do
      allow_any_instance_of(described_class).to receive(:max_ideas).and_return(2)
    end

    it "renders a warning about more ideas" do
      expect(subject).to have_content("more")
    end
  end
end