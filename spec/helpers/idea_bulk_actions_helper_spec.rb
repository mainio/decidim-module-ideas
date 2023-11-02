# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Ideas
    module Admin
      describe IdeaBulkActionsHelper do
        let(:participatory_space) { create(:participatory_process) }
        let(:user1) { create(:user, :admin, organization: participatory_space.organization) }
        let(:user2) { create(:user, :admin, organization: participatory_space.organization) }
        let!(:role1) { create(:participatory_process_user_role, user: user1, participatory_process: participatory_space, role: "valuator") }
        let!(:role2) { create(:participatory_process_user_role, user: user2, participatory_process: participatory_space, role: "valuator") }
        let(:prompt) { "Dummy prompt" }

        describe "bulk_valuators_select" do
          subject do
            Nokogiri::HTML(
              helper.bulk_valuators_select(participatory_space, prompt)
            )
          end

          it "renders the list of valuators correctly" do
            [role1, role2].each do |role|
              expect(subject).to have_selector("select#valuator_role_id option[value='#{role.id}']")
            end
            expect(subject).to have_content(user1.name)
            expect(subject).to have_content(user2.name)
          end

          it "does not include other roles" do
            user3 = create(:user, :admin, organization: participatory_space.organization)
            role3 = create(:participatory_process_user_role, user: user3, participatory_process: participatory_space, role: "moderator")
            expect(subject).not_to have_selector("select#valuator_role_id option[value='#{role3.id}']")
          end
        end
      end
    end
  end
end
