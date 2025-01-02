# frozen_string_literal: true

require "spec_helper"

module Decidim
  module ContentParsers
    describe IdeaParser do
      let(:organization) { create(:organization, tos_version: Time.current) }
      let(:component) { create(:idea_component, organization:) }
      let(:context) { { current_organization: organization } }
      let!(:parser) { described_class.new(content, context) }

      describe "ContentParser#parse is invoked" do
        let(:content) { "" }

        it "must call IdeaParser.parse" do
          allow(described_class).to receive(:new).with(content, context).and_return(parser)

          result = Decidim::ContentProcessor.parse(content, context)

          expect(result.rewrite).to eq ""
          expect(result.metadata[:idea].class).to eq Decidim::ContentParsers::IdeaParser::Metadata
        end
      end

      describe "on parse" do
        subject { parser.rewrite }

        context "when content is nil" do
          let(:content) { nil }

          it { is_expected.to eq("") }

          it "has empty metadata" do
            subject
            expect(parser.metadata).to be_a(Decidim::ContentParsers::IdeaParser::Metadata)
            expect(parser.metadata.linked_ideas).to eq([])
          end
        end

        context "when content is empty string" do
          let(:content) { "" }

          it { is_expected.to eq("") }

          it "has empty metadata" do
            subject
            expect(parser.metadata).to be_a(Decidim::ContentParsers::IdeaParser::Metadata)
            expect(parser.metadata.linked_ideas).to eq([])
          end
        end

        context "when conent has no links" do
          let(:content) { "whatever content with @mentions and #hashes but no links." }

          it { is_expected.to eq(content) }

          it "has empty metadata" do
            subject
            expect(parser.metadata).to be_a(Decidim::ContentParsers::IdeaParser::Metadata)
            expect(parser.metadata.linked_ideas).to eq([])
          end
        end

        context "when content links to an organization different from current" do
          let(:idea) { create(:idea, component:) }
          let(:external_idea) { create(:idea, component: create(:idea_component, organization: create(:organization, tos_version: Time.current))) }
          let(:content) do
            url = idea_url(external_idea)
            "This content references idea #{url}."
          end

          it "does not recognize the idea" do
            subject
            expect(parser.metadata.linked_ideas).to eq([])
          end
        end

        context "when content has one link" do
          let(:idea) { create(:idea, component:) }
          let(:content) do
            url = idea_url(idea)
            "This content references idea #{url}."
          end

          it { is_expected.to eq("This content references idea #{idea.to_global_id}.") }

          it "has metadata with the idea" do
            subject
            expect(parser.metadata).to be_a(Decidim::ContentParsers::IdeaParser::Metadata)
            expect(parser.metadata.linked_ideas).to eq([idea.id])
          end
        end

        context "when content has one link that is a simple domain" do
          let(:link) { "aaa:bbb" }
          let(:content) do
            "This content contains #{link} which is not a URI."
          end

          it { is_expected.to eq(content) }

          it "has metadata with the idea" do
            subject
            expect(parser.metadata).to be_a(Decidim::ContentParsers::IdeaParser::Metadata)
            expect(parser.metadata.linked_ideas).to be_empty
          end
        end

        context "when content has many links" do
          let(:first_idea) { create(:idea, component:) }
          let(:second_idea) { create(:idea, component:) }
          let(:third_idea) { create(:idea, component:) }
          let(:content) do
            url1 = idea_url(first_idea)
            url2 = idea_url(second_idea)
            url3 = idea_url(third_idea)
            "This content references the following ideas: #{url1}, #{url2} and #{url3}. Great?I like them!"
          end

          it { is_expected.to eq("This content references the following ideas: #{first_idea.to_global_id}, #{second_idea.to_global_id} and #{third_idea.to_global_id}. Great?I like them!") }

          it "has metadata with all linked ideas" do
            subject
            expect(parser.metadata).to be_a(Decidim::ContentParsers::IdeaParser::Metadata)
            expect(parser.metadata.linked_ideas).to eq([first_idea.id, second_idea.id, third_idea.id])
          end
        end

        context "when content has a link that is not in a ideas component" do
          let(:idea) { create(:idea, component:) }
          let(:content) do
            url = idea_url(idea).sub(%r{/ideas/}, "/something-else/")
            "This content references a non-idea with same ID as a idea #{url}."
          end

          it { is_expected.to eq(content) }

          it "has metadata with no reference to the idea" do
            subject
            expect(parser.metadata).to be_a(Decidim::ContentParsers::IdeaParser::Metadata)
            expect(parser.metadata.linked_ideas).to be_empty
          end
        end

        context "when content has words similar to links but not links" do
          let(:similars) do
            %w(AA:aaa AA:sss aa:aaa aa:sss aaa:sss aaaa:sss aa:ssss aaa:ssss)
          end
          let(:content) do
            "This content has similars to links: #{similars.join}. Great! Now are not treated as links"
          end

          it { is_expected.to eq(content) }

          it "has empty metadata" do
            subject
            expect(parser.metadata).to be_a(Decidim::ContentParsers::IdeaParser::Metadata)
            expect(parser.metadata.linked_ideas).to be_empty
          end
        end

        context "when idea in content does not exist" do
          let(:idea) { create(:idea, component:) }
          let(:url) { idea_url(idea) }
          let(:content) do
            idea.destroy
            "This content references idea #{url}."
          end

          it { is_expected.to eq("This content references idea #{url}.") }

          it "has empty metadata" do
            subject
            expect(parser.metadata).to be_a(Decidim::ContentParsers::IdeaParser::Metadata)
            expect(parser.metadata.linked_ideas).to eq([])
          end
        end

        context "when idea is linked via ID" do
          let(:idea) { create(:idea, component:) }
          let(:content) { "This content references idea ~#{idea.id}." }

          it { is_expected.to eq("This content references idea #{idea.to_global_id}.") }

          it "has metadata with the idea" do
            subject
            expect(parser.metadata).to be_a(Decidim::ContentParsers::IdeaParser::Metadata)
            expect(parser.metadata.linked_ideas).to eq([idea.id])
          end
        end
      end

      def idea_url(idea)
        Decidim::ResourceLocatorPresenter.new(idea).url
      end
    end
  end
end
