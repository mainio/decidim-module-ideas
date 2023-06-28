# frozen_string_literal: true

require "spec_helper"
require "decidim/core/test/shared_examples/counts_commentators_as_newsletter_participants"

describe Decidim::Ideas::Idea do
  subject { idea }

  let(:organization) { create(:organization) }
  let(:component) { build :idea_component, organization: organization }
  let(:idea) { create(:idea, component: component) }

  describe "newsletter participants" do
    subject { described_class.newsletter_participant_ids(idea.component) }

    let!(:component_out_of_newsletter) { create(:idea_component, organization: organization) }
    let!(:resource_out_of_newsletter) { create(:idea, component: component_out_of_newsletter) }
    let!(:resource_in_newsletter) { create(:idea, component: idea.component) }
    let(:author_ids) { idea.notifiable_identities.pluck(:id) + resource_in_newsletter.notifiable_identities.pluck(:id) }

    include_examples "counts commentators as newsletter participants"
  end

  describe "data portability images" do
    let!(:image) { create(:attachment, attached_to: idea) }
    let(:user) { idea.authors.first }

    it "matches attachment" do
      expect(described_class.data_portability_images(user).first.first.record.title).to eq(image.title)
      expect(described_class.data_portability_images(user).first.first.record.content_type).to eq(image.content_type)
      expect(described_class.data_portability_images(user).first.first.record.file_size).to eq(image.file_size)
    end
  end

  context "when it has been accepted" do
    let(:idea) { build(:idea, :accepted) }

    it { is_expected.to be_answered }
    it { is_expected.to be_published_state }
    it { is_expected.to be_accepted }
  end

  context "when it has been rejected" do
    let(:idea) { build(:idea, :rejected) }

    it { is_expected.to be_answered }
    it { is_expected.to be_published_state }
    it { is_expected.to be_rejected }
  end

  describe "#users_to_notify_on_comment_created" do
    let!(:follows) { create_list(:follow, 3, followable: subject) }
    let(:followers) { follows.map(&:user) }
    let(:participatory_space) { subject.component.participatory_space }
    let!(:participatory_process_admin) do
      create(:process_admin, participatory_process: participatory_space)
    end

    context "when the idea is not official" do
      it "returns the followers and the author" do
        expect(subject.users_to_notify_on_comment_created).to match_array(followers.concat([idea.creator.author]))
      end
    end

    describe "#editable_by?" do
      let(:author) { create(:user, organization: organization) }

      context "when user is author" do
        let(:idea) { create :idea, component: component, users: [author], updated_at: Time.current }

        it { is_expected.to be_editable_by(author) }

        context "when the idea has been linked to another one" do
          let(:idea) { create :idea, component: component, users: [author], updated_at: Time.current }
          let(:original_idea) do
            original_component = create(:idea_component, organization: organization, participatory_space: component.participatory_space)
            create(:idea, component: original_component)
          end

          before do
            idea.link_resources([original_idea], "copied_from_component")
          end

          it { is_expected.not_to be_editable_by(author) }
        end
      end

      context "when idea is from user group and user is admin" do
        let(:user_group) { create :user_group, :verified, users: [author], organization: author.organization }
        let(:idea) { create :idea, component: component, updated_at: Time.current, users: [author], user_groups: [user_group] }

        it { is_expected.to be_editable_by(author) }
      end

      context "when user is not the author" do
        let(:idea) { create :idea, component: component, updated_at: Time.current }

        it { is_expected.not_to be_editable_by(author) }
      end

      context "when idea is answered" do
        let(:idea) { build :idea, :with_answer, component: component, updated_at: Time.current, users: [author] }

        it { is_expected.not_to be_editable_by(author) }
      end

      context "when idea editing time has run out" do
        let(:idea) { build :idea, updated_at: 1.year.ago, component: component, users: [author] }

        it { is_expected.not_to be_editable_by(author) }
      end
    end

    describe "#withdrawn?" do
      context "when idea is withdrawn" do
        let(:idea) { build :idea, :withdrawn }

        it { is_expected.to be_withdrawn }
      end

      context "when idea is not withdrawn" do
        let(:idea) { build :idea }

        it { is_expected.not_to be_withdrawn }
      end
    end

    describe "#withdrawable_by" do
      let(:author) { create(:user, organization: organization) }

      context "when user is author" do
        let(:idea) { create :idea, component: component, users: [author], created_at: Time.current }

        it { is_expected.to be_withdrawable_by(author) }
      end

      context "when user is admin" do
        let(:admin) { build(:user, :admin, organization: organization) }
        let(:idea) { build :idea, component: component, users: [author], created_at: Time.current }

        it { is_expected.not_to be_withdrawable_by(admin) }
      end

      context "when user is not the author" do
        let(:someone_else) { build(:user, organization: organization) }
        let(:idea) { build :idea, component: component, users: [author], created_at: Time.current }

        it { is_expected.not_to be_withdrawable_by(someone_else) }
      end

      context "when idea is already withdrawn" do
        let(:idea) { build :idea, :withdrawn, component: component, users: [author], created_at: Time.current }

        it { is_expected.not_to be_withdrawable_by(author) }
      end

      context "when the idea has been linked to another one" do
        let(:idea) { create :idea, component: component, users: [author], created_at: Time.current }
        let(:original_idea) do
          original_component = create(:idea_component, organization: organization, participatory_space: component.participatory_space)
          create(:idea, component: original_component)
        end

        before do
          idea.link_resources([original_idea], "copied_from_component")
        end

        it { is_expected.not_to be_withdrawable_by(author) }
      end
    end

    context "when answer is not published" do
      let(:idea) { create(:idea, :accepted_not_published, component: component) }

      it "has accepted as the internal state" do
        expect(idea.internal_state).to eq("accepted")
      end

      it "has not_answered as public state" do
        expect(idea.state).to be_nil
      end

      it { is_expected.not_to be_accepted }
      it { is_expected.to be_answered }
      it { is_expected.not_to be_published_state }
    end
  end
end
