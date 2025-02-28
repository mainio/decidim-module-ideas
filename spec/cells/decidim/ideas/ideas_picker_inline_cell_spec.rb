# frozen_string_literal: true

require "spec_helper"

describe Decidim::Ideas::IdeasPickerInlineCell, type: :cell do
  controller Decidim::Ideas::IdeasController

  subject { my_cell.call }

  let(:my_cell) { cell("decidim/ideas/ideas_picker_inline", component, context: { form: }) }

  let(:record) { OpenStruct.new(ideas:) }
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
  let!(:ideas) { create_list(:idea, 30, component:) }

  before do
    allow(controller).to receive(:current_participatory_space).and_return(participatory_space)
  end

  it "renders accepted ideas" do
    ideas.each do |idea|
      expect(subject).to have_content("##{idea.id} - #{translated(idea.title)}")
    end
  end

  it "renders the inputs toselect each idea" do
    ideas.each do |idea|
      expect(subject).to have_css("input[name='record[idea_ids][]'][value='#{idea.id}']", visible: :hidden)
    end
  end
end
