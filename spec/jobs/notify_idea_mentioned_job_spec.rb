# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Ideas
    describe NotifyIdeasMentionedJob do
      let(:organization) { create(:organization) }
      let(:participatory_process) { create :participatory_process, organization: organization }
      let(:author) { create(:user, :confirmed, organization: organization) }
      let(:component) { create(:component, participatory_space: participatory_process) }
      let(:idea_component) { create(:idea_component, participatory_space: participatory_process) }
      let(:idea) { create(:idea, :accepted, :published, component: idea_component, users: [author]) }
      let(:comment) { create(:comment, commentable: idea) }

      it "notifies mentioned" do
        expect(::Decidim::EventsManager)
          .to receive(:publish)
          .with(
            event: "decidim.events.ideas.idea_mentioned",
            event_class: Decidim::Ideas::IdeaMentionedEvent,
            resource: idea,
            affected_users: [author],
            extra: {
              comment_id: comment.id,
              mentioned_idea_id: idea.id
            }
          )
        NotifyIdeasMentionedJob.perform_now(comment.id, [idea.id])
      end
    end
  end
end
