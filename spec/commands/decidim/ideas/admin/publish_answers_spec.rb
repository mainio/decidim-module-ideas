# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Ideas
    module Admin
      describe PublishAnswers do
        subject { command.call }

        let(:command) { described_class.new(component, user, idea_ids) }
        let(:idea_ids) { ideas.map(&:id) }
        let(:ideas) { create_list(:idea, 5, :accepted_not_published, component:) }
        let(:component) { create(:idea_component) }
        let(:user) { create(:user, :confirmed, :admin) }

        it "broadcasts ok" do
          expect { subject }.to broadcast(:ok)
        end

        it "publish the answers" do
          expect { subject }.to change { ideas.map { |idea| idea.reload.published_state? }.uniq }.to([true])
        end

        it "changes the ideas published state" do
          expect { subject }.to change { ideas.map { |idea| idea.reload.state }.uniq }.from([nil]).to(["accepted"])
        end

        it "traces the action", versioning: true do
          ideas.each do |idea|
            expect(Decidim.traceability)
              .to receive(:perform_action!)
              .with("publish_answer", idea, user)
              .and_call_original
          end

          expect { subject }.to change(Decidim::ActionLog, :count)
          idea_version = Decidim::Ideas::IdeaVersion.last
          expect(idea_version).to be_present
          expect(idea_version.event).to eq "update"
        end

        it "notifies the answers" do
          ideas.each do |idea|
            expect(NotifyIdeaAnswer)
              .to receive(:call)
              .with(idea, nil)
          end

          subject
        end

        context "when idea ids belong to other component" do
          let(:ideas) { create_list(:idea, 5, :accepted) }

          it "broadcasts invalid" do
            expect { subject }.to broadcast(:invalid)
          end

          it "doesn't publish the answers" do
            expect { subject }.not_to(change { ideas.map { |idea| idea.reload.published_state? }.uniq })
          end

          it "doesn't trace the action" do
            expect(Decidim.traceability)
              .not_to receive(:perform_action!)

            subject
          end

          it "doesn't notify the answers" do
            expect(NotifyIdeaAnswer).not_to receive(:call)

            subject
          end
        end
      end
    end
  end
end
