# frozen_string_literal: true

require "spec_helper"

describe Decidim::Ideas::Log::ResourcePresenter, type: :helper do
  let(:presenter) { described_class.new(resource, helper, extra) }
  let(:resource) { create(:idea, title: "Resource presenter idea") }
  let(:extra) { {} }

  let(:component) { resource.component }
  let(:participatory_space) { component.participatory_space }

  describe "#present" do
    subject { presenter.present }

    it "presents a link to the resource" do
      expect(subject).to eq(
        %(<a class="logs__log__resource" href="/processes/#{participatory_space.slug}/f/#{component.id}/ideas/#{resource.id}">Resource presenter idea</a>)
      )
    end

    context "when the resource does not exist" do
      let(:resource) { nil }

      before do
        helper.extend(Decidim::ApplicationHelper)
        helper.extend(Decidim::TranslationsHelper)
      end

      it "presents a span element" do
        expect(subject).to eq(%(<span class="logs__log__resource"></span>))
      end
    end
  end
end
