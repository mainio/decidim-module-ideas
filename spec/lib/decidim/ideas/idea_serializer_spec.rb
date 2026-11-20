# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Ideas
    describe IdeaSerializer do
      subject { described_class.new(idea) }

      let(:component) { create(:idea_component) }
      let(:participatory_process) { component.participatory_space }
      let(:organization) { participatory_process.organization }
      let(:taxonomy_filter) { create(:idea_taxonomy_filter, organization:) }
      let(:taxonomy) { taxonomy_filter.root_taxonomy.children.first }
      let(:idea) { create(:idea, component:, category: false, area_scope: false, taxonomies: [taxonomy]) }

      describe "#serialize" do
        let(:serialized) { subject.serialize }

        it "serializes the id" do
          expect(serialized).to include(id: idea.id)
        end

        it "serializes the reference" do
          expect(serialized[:reference]).to eq(idea.reference)
        end

        it "serializes the participatory space" do
          expect(serialized[:participatory_space]).to include(id: idea.participatory_space.id)
          expect(serialized[:participatory_space]).to include(url: Decidim::ResourceLocatorPresenter.new(idea.participatory_space).url)
        end

        it "serializes the component" do
          expect(serialized[:component][:id]).to eq(component.id)
        end

        it "serializes the taxonomies" do
          expect(serialized[:taxonomies]).to be_present
        end

        it "serializes the title" do
          expect(serialized).to include(title: idea.title)
        end

        it "serializes the body" do
          expect(serialized).to include(body: idea.body)
        end

        it "serializes the address" do
          expect(serialized).to include(address: idea.address)
        end

        it "serializes the coordinates" do
          expect(serialized[:coordinates]).to include(
            available: false,
            latitude: nil,
            longitude: nil
          )
        end

        it "serializes state" do
          expect(serialized).to include(state: idea.state.to_s)
        end

        context "with proposal having an answer" do
          let!(:idea) { create(:idea, :with_answer, category: false, area_scope: false) }

          it "serializes answer" do
            expect(serialized).to include(answer: idea.answer.reject { |k| k == "machine_translations" }.merge("es" => ""))
          end
        end

        it "serializes the amount of comments" do
          expect(serialized).to include(comments: idea.comments_count)
        end

        it "serializes the amount of attachments" do
          expect(serialized).to include(attachments: idea.attachments.count)
        end

        it "serializes the amount of followers" do
          expect(serialized).to include(followers: idea.followers.count)
        end

        it "serializes published at" do
          expect(serialized).to include(published_at: idea.published_at)
        end

        it "serializes url" do
          expect(serialized).to include(url: Decidim::ResourceLocatorPresenter.new(idea).url)
        end

        it "serializes is amend" do
          expect(serialized).to include(is_amend: idea.emendation?)
        end

        context "when the idea has coordinates" do
          let(:geocoding_component) { create(:idea_component, :with_geocoding_enabled, participatory_space: participatory_process) }
          let(:idea) { create(:idea, :geocoded, component: geocoding_component, category: false, area_scope: false) }

          it "serializes the coordinates" do
            expect(serialized[:coordinates]).to include(
              available: true,
              latitude: idea.latitude,
              longitude: idea.longitude
            )
          end
        end

        context "when the taxonomy has coordinates defined in the component settings" do
          let(:coordinates) do
            {
              latitude: ::Faker::Address.latitude,
              longitude: ::Faker::Address.longitude
            }
          end

          before do
            component.update!(
              settings: {
                area_taxonomy_filter_id: taxonomy_filter.id,
                area_scope_coordinates: {
                  taxonomy.id.to_s => "#{coordinates[:latitude]},#{coordinates[:longitude]}"
                }
              }
            )
          end

          it "serializes the taxonomy coordinates" do
            expect(serialized[:coordinates]).to include(
              available: false,
              latitude: coordinates[:latitude],
              longitude: coordinates[:longitude]
            )
          end
        end
      end
    end
  end
end
