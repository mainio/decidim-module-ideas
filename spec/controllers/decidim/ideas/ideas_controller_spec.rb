# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Ideas
    describe IdeasController do
      routes { Decidim::Ideas::Engine.routes }

      let(:user) { create(:user, :confirmed, organization: component.organization) }

      let(:idea_params) do
        {
          component_id: component.id
        }
      end
      let(:params) { { idea: idea_params } }

      before do
        request.env["decidim.current_organization"] = component.organization
        request.env["decidim.current_participatory_space"] = component.participatory_space
        request.env["decidim.current_component"] = component
      end

      describe "GET index" do
        context "when participatory texts are disabled" do
          let(:component) { create(:idea_component, :with_geocoding_enabled) }

          it "sets two different collections" do
            _geocoded_ideas = create_list(:idea, 10, component:, latitude: 1.1, longitude: 2.2)
            _non_geocoded_ideas = create_list(:idea, 2, component:, latitude: nil, longitude: nil)

            get :index
            expect(response).to have_http_status(:ok)
            expect(subject).to render_template(:index)

            expect(assigns(:ideas).count).to eq 12
          end
        end
      end

      describe "GET new" do
        let(:component) { create(:idea_component, :with_creation_enabled) }

        before { sign_in user }

        context "when NO draft ideas exist" do
          it "renders the empty form" do
            get(:new, params:)
            expect(response).to have_http_status(:ok)
            expect(subject).to render_template(:new)
          end
        end

        context "when draft ideas exist from other users" do
          let!(:others_draft) { create(:idea, :draft, component:) }

          it "renders the empty form" do
            get(:new, params:)
            expect(response).to have_http_status(:ok)
            expect(subject).to render_template(:new)
          end
        end
      end

      describe "POST create" do
        before { sign_in user }

        context "when creation is not enabled" do
          let(:component) { create(:idea_component) }

          it "raises an error" do
            post(:create, params:)

            expect(flash[:alert]).not_to be_empty
          end
        end

        context "when creation is enabled" do
          let(:component) { create(:idea_component, :with_creation_enabled) }
          let(:idea_params) do
            {
              component_id: component.id,
              title: "Lorem ipsum dolor sit amet, consectetur adipiscing elit",
              body: "Ut sed dolor vitae purus volutpat venenatis. Donec sit amet sagittis sapien. Curabitur rhoncus ullamcorper feugiat. Aliquam et magna metus.",
              terms_agreed: "1"
            }
          end

          it "creates a idea" do
            post(:create, params:)

            expect(response).to have_http_status(:found)
          end
        end
      end

      describe "PATCH update" do
        let(:component) { create(:idea_component, :with_creation_enabled, :with_attachments_allowed) }
        let(:idea) { create(:idea, component:, users: [user]) }
        let(:idea_params) do
          {
            title: "Lorem ipsum dolor sit amet, consectetur adipiscing elit",
            body: "Ut sed dolor vitae purus volutpat venenatis. Donec sit amet sagittis sapien. Curabitur rhoncus ullamcorper feugiat. Aliquam et magna metus.",
            terms_agreed: "1"
          }
        end
        let(:params) do
          {
            id: idea.id,
            idea: idea_params
          }
        end

        before { sign_in user }

        it "updates the idea" do
          patch(:update, params:)

          expect(response).to have_http_status(:found)
        end
      end

      describe "withdraw an idea" do
        let(:component) { create(:idea_component, :with_creation_enabled) }

        before { sign_in user }

        context "when an authorized user is withdrawing a idea" do
          let(:idea) { create(:idea, component:, users: [user]) }

          it "withdraws the idea" do
            put :withdraw, params: params.merge(id: idea.id)

            expect(flash[:notice]).to eq("Idea successfully updated.")
            expect(response).to have_http_status(:found)
            idea.reload
            expect(idea.withdrawn?).to be true
          end
        end

        describe "when current user is NOT the author of the idea" do
          let(:current_user) { create(:user, :confirmed, organization: component.organization) }
          let(:idea) { create(:idea, component:, users: [current_user]) }

          context "and the idea has no supports" do
            it "is not able to withdraw the idea" do
              expect(WithdrawIdea).not_to receive(:call)

              put :withdraw, params: params.merge(id: idea.id)

              expect(flash[:alert]).to eq("You are not authorized to perform this action.")
              expect(response).to have_http_status(:found)
              idea.reload
              expect(idea.withdrawn?).to be false
            end
          end
        end
      end

      describe "GET show" do
        let!(:component) { create(:idea_component, :with_amendments_enabled) }
        let!(:amendable) { create(:idea, component:) }
        let!(:emendation) { create(:idea, component:) }
        let!(:amendment) { create(:amendment, amendable:, emendation:) }
        let(:active_step_id) { component.participatory_space.active_step.id }

        context "when the idea is an amendable" do
          it "shows the idea" do
            get :show, params: params.merge(id: amendable.id)
            expect(response).to have_http_status(:ok)
            expect(subject).to render_template(:show)
          end

          it "redirects to amendable" do
            get :show, params: params.merge(id: emendation.id)
            expect(response).to have_http_status(:found)
            expect(subject).to redirect_to("/processes/#{component.participatory_space.slug}/f/#{component.id}/ideas/#{amendable.id}")
          end
        end

        context "when the idea is an emendation" do
          context "and amendments VISIBILITY is set to 'participants'" do
            before do
              component.update!(step_settings: { active_step_id => { amendments_visibility: "participants" } })
            end

            context "when the user is not logged in" do
              it "redirects to 404" do
                expect do
                  get :show, params: params.merge(id: emendation.id)
                end.to raise_error(ActionController::RoutingError)
              end
            end

            context "when the user is logged in" do
              before { sign_in user }

              context "and is NOT the author of the emendation" do
                it "redirects to 404" do
                  expect do
                    get :show, params: params.merge(id: emendation.id)
                  end.to raise_error(ActionController::RoutingError)
                end
              end
            end
          end
        end
      end
    end
  end
end
