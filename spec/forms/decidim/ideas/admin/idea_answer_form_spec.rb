# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Ideas
    module Admin
      describe IdeaAnswerForm do
        subject { form }

        let(:organization) { ideas_component.participatory_space.organization }
        let(:state) { "accepted" }
        let(:answer) { Decidim::Faker::Localized.sentence(word_count: 3) }
        let(:ideas_component) { create(:idea_component) }
        let(:execution_period) { nil }
        let(:params) do
          {
            internal_state: state,
            answer:,
            execution_period:
          }
        end

        let(:form) do
          described_class.from_params(params).with_context(
            current_component: ideas_component,
            current_organization: organization
          )
        end

        context "when everything is OK" do
          it { is_expected.to be_valid }
        end

        context "when the state is not valid" do
          let(:state) { "foo" }

          it { is_expected.to be_invalid }
        end

        context "when there's no state" do
          let(:state) { nil }

          it { is_expected.to be_invalid }
        end

        context "when rejecting a idea" do
          let(:state) { "rejected" }

          context "and there's no answer" do
            let(:answer) { nil }

            it { is_expected.to be_invalid }
          end
        end
      end
    end
  end
end
