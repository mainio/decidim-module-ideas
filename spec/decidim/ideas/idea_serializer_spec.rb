# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Ideas
    describe IdeaSerializer do
      subject { described_class.new(idea) }

      let(:idea) { create(:idea, component: component) }
      let!(:category) { create(:category, participatory_space: component.participatory_space) }
      let!(:scope) { create(:scope, organization: component.participatory_space.organization) }
      let(:participatory_process) { component.participatory_space }
      let(:component) { create(:idea_component) }

      before do
        idea.update(category: category)
        idea.update(area_scope: scope)
      end

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

        it "serializes the area scope" do
          expect(serialized[:area_scope]).to include(id: scope.id)
          expect(serialized[:area_scope]).to include(name: scope.name)
        end

        it "serializes the category" do
          expect(serialized[:category]).to include(id: category.id)
          expect(serialized[:category]).to include(name: category.name)
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

        it "serializes latidute" do
          expect(serialized).to include(latitude: idea.latitude)
        end

        it "serializes longitude" do
          expect(serialized).to include(latitude: idea.longitude)
        end

        it "serializes state" do
          expect(serialized).to include(state: idea.state.to_s)
        end

        context "with proposal having an answer" do
          let!(:idea) { create(:idea, :with_answer) }

          it "serializes answer" do
            expect(serialized).to include(answer: idea.answer)
          end
        end

        it "serializes the amount of supports" do
          expect(serialized).to include(supports: idea.idea_votes_count)
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

        # context "when idea has orginal idea" do
        #   let!(:original) { create(:idea) }

        #   before do
        #     original.update(category: category)
        #     original.update(area_scope: scope)
        #     idea.amendable = original
        #   end

          # Failure/Error: return amendment.state if emendation?

          # NoMethodError:
          #   undefined method `state' for nil:NilClass
          # ./app/models/decidim/ideas/idea.rb:225:in `state'

          # it "serializes the orginal idea" do
          #   expect(serialized[:original_idea]).to include(title: original.title)
          # end
        # end
      end
    end
  end
end
