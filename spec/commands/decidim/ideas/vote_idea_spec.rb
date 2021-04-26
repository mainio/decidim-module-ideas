# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Ideas
    describe VoteIdea do
      describe "call" do
        let(:idea) { create(:idea) }
        let(:current_user) { create(:user, organization: idea.component.organization) }
        let(:command) { described_class.new(idea, current_user) }

        context "with normal conditions" do
          it "broadcasts ok" do
            expect { command.call }.to broadcast(:ok)
          end

          it "creates a new vote for the idea" do
            expect do
              command.call
            end.to change(IdeaVote, :count).by(1)
          end
        end

        context "when the vote is not valid" do
          before do
            # rubocop:disable RSpec/AnyInstance
            allow_any_instance_of(IdeaVote).to receive(:valid?).and_return(false)
            # rubocop:enable RSpec/AnyInstance
          end

          it "broadcasts invalid" do
            expect { command.call }.to broadcast(:invalid)
          end

          it "doesn't create a new vote for the idea" do
            expect do
              command.call
            end.to change(IdeaVote, :count).by(0)
          end
        end

        context "when the threshold have been reached" do
          before do
            expect(idea).to receive(:maximum_votes_reached?).and_return(true)
          end

          it "broadcasts invalid" do
            expect { command.call }.to broadcast(:invalid)
          end
        end

        context "when the threshold have been reached but idea can accumulate more votes" do
          before do
            expect(idea).to receive(:maximum_votes_reached?).and_return(true)
            expect(idea).to receive(:can_accumulate_supports_beyond_threshold).and_return(true)
          end

          it "creates a new vote for the idea" do
            expect do
              command.call
            end.to change(IdeaVote, :count).by(1)
          end
        end
      end
    end
  end
end
