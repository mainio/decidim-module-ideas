# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Ideas
    module Admin
      describe IdeasHelper do
        helper ::Decidim::Ideas::ApplicationHelper
        helper ::Decidim::ApplicationHelper
        let(:component) { create(:idea_component, participatory_space:) }
        let(:idea) { create(:idea, :draft, component:, users: [first_author, second_author]) }
        let(:organization) { create(:organization, tos_version: Time.current) }
        let(:participatory_space) { create(:participatory_process, :with_steps, organization:) }
        let(:first_author) { create(:user, :confirmed, organization:) }
        let(:second_author) { create(:user, :confirmed, organization:) }

        describe "coauthor_presenters_for" do
          subject { helper.coauthor_presenters_for(idea) }
          it "returns authors" do
            expect(subject).to include(first_author)
            expect(subject).to include(second_author)
          end

          context "with user group" do
            let!(:second_author) { create(:user_group, organization:) }

            it "returns authors" do
              expect(subject).to include(first_author)
              expect(subject).to include(second_author)
            end
          end
        end

        describe "idea_complete_state" do
          subject { helper.idea_complete_state(idea) }

          context "when not answered" do
            let(:idea) { create(:idea, :not_answered, component:) }

            it "returns state" do
              expect(subject).to eq("Not answered")
            end
          end

          context "when answered and not published" do
            let(:idea) { create(:idea, :accepted_not_published, component:) }

            it "returns state" do
              expect(subject).to eq("Not answered (Accepted to the next step)")
            end
          end
        end
      end
    end
  end
end
