# frozen_string_literal: true

require "spec_helper"

describe Decidim::Ideas::IdeaPresenter do
  let(:presenter) { described_class.new(idea) }
  let(:idea) { create(:idea, component:) }

  let(:organization) { create(:organization, tos_version: Time.current) }
  let(:participatory_space) { create(:participatory_process, :with_steps, organization:) }
  let(:component) { create(:idea_component, participatory_space:) }

  let(:idea_link) { "/processes/#{participatory_space.slug}/f/#{component.id}/ideas/#{idea.id}" }

  describe "#idea_path" do
    subject { presenter.idea_path }

    it "returns the path to the idea" do
      expect(subject).to eq(idea_link)
    end
  end

  describe "#display_mention" do
    subject { presenter.display_mention }

    it "shows the mention" do
      expect(subject).to include(escaped_html(idea.title))
    end

    it "shows the link to the resource" do
      expect(subject).to include(idea_link)
    end
  end

  describe "#title" do
    subject { presenter.title }

    it "displays the idea title" do
      expect(subject).to eq(idea.title)
    end

    context "with HTML escaping" do
      subject { presenter.title(html_escape: true) }

      it "escapes the title" do
        expect(subject).to include(escaped_html(idea.title))
      end
    end

    context "with hashtags" do
      subject { presenter.title }

      let(:idea) { create(:idea, title: title_with_hashtags, component:) }
      let(:title) { "Idea title with #decidim hashtag" }
      let(:title_with_hashtags) { Decidim::ContentProcessor.parse_with_processor(:hashtag, title, current_organization: organization).rewrite }

      it "presents the hashtags" do
        expect(subject).to eq(title)
      end

      context "with links" do
        subject { presenter.title(links: true) }

        it "adds the links to the hashtags" do
          expect(subject).to eq(
            %(Idea title with <a target="_blank" class="text-secondary underline" rel="noopener" data-external-link="false" href="/search?term=%23decidim">#decidim</a> hashtag)
          )
        end
      end
    end
  end

  describe "#id_and_title" do
    subject { presenter.id_and_title }

    it "prepends the idea ID to the title" do
      expect(subject).to eq("##{idea.id} - #{idea.title}")
    end
  end

  describe "#body" do
    subject { presenter.body }

    let(:idea) { create(:idea, body:, component:) }
    let(:body) do
      <<~BODY
        This is the idea body.

        Another paragraph.
      BODY
    end

    it "renders the body" do
      expect(subject).to eq(body)
    end

    context "with links" do
      subject { presenter.body(links: true) }

      let(:body) do
        <<~TEXT
          This is the idea body.

          https://decidim.org
        TEXT
      end

      it "renders the body with links" do
        expect(subject).to eq(
          <<~HTML
            This is the idea body.

            <a href="https://decidim.org" target="_blank" rel="nofollow noopener noreferrer ugc">https://decidim.org</a>
          HTML
        )
      end
    end

    context "with strip tags" do
      subject { presenter.body(strip_tags: true) }

      let(:body) { "<p>First paragraph.</p><p>Second paragraph.</p>" }

      it "strips the tags" do
        expect(subject).to eq(
          <<~TEXT.strip
            First paragraph.

            Second paragraph.
          TEXT
        )
      end
    end
  end

  describe "#area_scope_name" do
    subject { presenter.area_scope_name }

    it "displays the area scope name" do
      expect(subject).to eq(translated(idea.area_scope.name))
    end

    context "when the idea does not have an area scope" do
      let(:idea) { create(:idea, area_scope: false, component:) }

      it "returns nil" do
        expect(subject).to be_nil
      end
    end
  end

  describe "#category_name" do
    subject { presenter.category_name }

    it "displays the area scope name" do
      expect(subject).to eq(translated(idea.category.name))
    end

    context "when the idea does not have a category" do
      let(:idea) { create(:idea, category: false, component:) }

      it "returns nil" do
        expect(subject).to be_nil
      end
    end
  end

  describe "#published_date" do
    subject { presenter.published_date }

    it "displays the publish date in correct format" do
      expect(subject).to eq(I18n.l(idea.published_at.to_date, format: :decidim_short))
    end

    context "when the idea is not published" do
      let(:idea) { create(:idea, :draft, component:) }

      it "returns nil" do
        expect(subject).to be_nil
      end
    end
  end

  describe "#versions", versioning: true do
    subject { presenter.versions }

    let(:admin) { create(:user, :confirmed, :admin, organization:) }

    before do
      # Same update twice on purpose as it should not return duplicate changes.
      Decidim.traceability.update!(idea, idea.authors.first, title: "Updated idea title")
      Decidim.traceability.update!(idea, idea.authors.first, title: "Updated idea title")
      Decidim.traceability.update!(idea, admin, state: "evaluating", state_published_at: Time.current)
      Decidim.traceability.update!(idea, admin, state: "accepted", state_published_at: Time.current)
    end

    it "returns the state changes" do
      expect(subject.count).to be(4)
      expect(subject.select { |v| v.event == "create" }.count).to be(1)
      expect(subject.select { |v| v.event == "update" }.count).to be(3)
    end
  end

  def escaped_html(string)
    CGI.escapeHTML(string)
  end
end
