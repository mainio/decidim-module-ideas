# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Ideas
    module Admin
      describe IdeasHelper do
        helper ::Decidim::Ideas::ApplicationHelper
        helper ::Decidim::ApplicationHelper
        let(:component) { create(:idea_component, participatory_space: participatory_space) }
        let(:idea) { create(:idea, :draft, component: component, users: [author1, author2]) }
        let(:organization) { create(:organization, tos_version: Time.current) }
        let(:participatory_space) { create(:participatory_process, :with_steps, organization: organization) }
        let(:author1) { create(:user, :confirmed, organization: organization) }
        let(:author2) { create(:user, :confirmed, organization: organization) }

        describe "coauthor_presenters_for" do
          subject { helper.coauthor_presenters_for(idea) }
          it "returns authors" do
            expect(subject).to include(author1)
            expect(subject).to include(author2)
          end

          context "with user group" do
            let!(:author2) { create(:user_group, organization: organization) }

            it "returns authors" do
              expect(subject).to include(author1)
              expect(subject).to include(author2)
            end
          end
        end

        describe "idea_complete_state" do
          subject { helper.idea_complete_state(idea) }

          context "when not answered" do
            let(:idea) { create(:idea, :not_answered, component: component) }

            it "returns state" do
              expect(subject).to eq("Not answered")
            end
          end

          context "when answered and not published" do
            let(:idea) { create(:idea, :answered, :unpublished, component: component) }

            it "returns state" do
              expect(subject).to eq("Answered Not published")
            end
          end
        end
      end
    end
  end
end
