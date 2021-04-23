# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Ideas
    module Admin
      describe NotifyIdeaAnswer do
        subject { command.call }

        let(:command) { described_class.new(idea, initial_state) }
        let(:idea) { create(:idea, :accepted) }
        let(:initial_state) { nil }
        let(:current_user) { create(:user, :admin) }
        let(:follow) { create(:follow, followable: idea, user: follower) }
        let(:follower) { create(:user, organization: idea.organization) }

        before do
          follow

          # give idea author initial points to avoid unwanted events during tests
          Decidim::Gamification.increment_score(idea.creator_author, :accepted_ideas)
        end

        it "broadcasts ok" do
          expect { subject }.to broadcast(:ok)
        end

        it "notifies the idea followers" do
          expect(Decidim::EventsManager)
            .to receive(:publish)
            .with(
              event: "decidim.events.ideas.idea_accepted",
              event_class: Decidim::Ideas::AcceptedIdeaEvent,
              resource: idea,
              affected_users: match_array([idea.creator_author]),
              followers: match_array([follower])
            )

          subject
        end

        it "increments the accepted ideas counter" do
          expect { subject }.to change { Gamification.status_for(idea.creator_author, :accepted_ideas).score }.by(1)
        end

        context "when the idea is rejected after being accepted" do
          let(:idea) { create(:idea, :rejected) }
          let(:initial_state) { "accepted" }

          it "broadcasts ok" do
            expect { subject }.to broadcast(:ok)
          end

          it "notifies the idea followers" do
            expect(Decidim::EventsManager)
              .to receive(:publish)
              .with(
                event: "decidim.events.ideas.idea_rejected",
                event_class: Decidim::Ideas::RejectedIdeaEvent,
                resource: idea,
                affected_users: match_array([idea.creator_author]),
                followers: match_array([follower])
              )

            subject
          end

          it "decrements the accepted ideas counter" do
            expect { subject }.to change { Gamification.status_for(idea.coauthorships.first.author, :accepted_ideas).score }.by(-1)
          end
        end

        context "when the idea published state has not changed" do
          let(:initial_state) { "accepted" }

          it "broadcasts ok" do
            expect { command.call }.to broadcast(:ok)
          end

          it "doesn't notify the idea followers" do
            expect(Decidim::EventsManager)
              .not_to receive(:publish)

            subject
          end

          it "doesn't modify the accepted ideas counter" do
            expect { subject }.not_to(change { Gamification.status_for(current_user, :accepted_ideas).score })
          end
        end
      end
    end
  end
end
