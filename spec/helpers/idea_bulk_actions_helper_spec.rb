# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Ideas
    module Admin
      describe IdeaBulkActionsHelper do
        let(:participatory_space) { create(:participatory_process) }
        let(:first_user) { create(:user, :admin, organization: participatory_space.organization) }
        let(:second_user) { create(:user, :admin, organization: participatory_space.organization) }
        let!(:first_role) { create(:participatory_process_user_role, user: first_user, participatory_process: participatory_space, role: "valuator") }
        let!(:second_role) { create(:participatory_process_user_role, user: second_user, participatory_process: participatory_space, role: "valuator") }
        let(:prompt) { "Dummy prompt" }

        describe "bulk_valuators_select" do
          subject do
            Nokogiri::HTML(
              helper.bulk_valuators_select(participatory_space, prompt)
            )
          end

          it "renders the list of valuators correctly" do
            [first_role, second_role].each do |role|
              expect(subject).to have_css("select#valuator_role_id option[value='#{role.id}']")
            end
            expect(subject).to have_content(first_user.name)
            expect(subject).to have_content(second_user.name)
          end

          it "does not include other roles" do
            user3 = create(:user, :admin, organization: participatory_space.organization)
            role3 = create(:participatory_process_user_role, user: user3, participatory_process: participatory_space, role: "moderator")
            expect(subject).to have_no_css("select#valuator_role_id option[value='#{role3.id}']")
          end
        end
      end
    end
  end
end
