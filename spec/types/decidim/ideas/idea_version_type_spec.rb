# frozen_string_literal: true

require "spec_helper"
require "decidim/api/test/type_context"

describe Decidim::Ideas::IdeaVersionType, type: :graphql do
  include_context "with a graphql type"

  # After upgrade to 0.24, the schema definition and response can be
  # removed. They are workarounds to make it work with the old schema in
  # 0.23.
  let(:schema) { Decidim::Api::Schema }
  let(:response) do
    actual_query = %(
      {
        participatoryProcess(id: #{participatory_process.id}){
          components{
            ...on Ideas{
              ideas{
                edges{
                  node{
                    versions #{query}
                  }
                }
              }
            }
          }
        }
      }
    )
    resp = execute_query actual_query, variables.stringify_keys
    resp["participatoryProcess"]["components"].first["ideas"]["edges"].first["node"]["versions"].first
  end

  let!(:component) do
    create(:idea_component,
           :with_creation_enabled,
           participatory_space: participatory_process)
  end
  let!(:participatory_process) { create :participatory_process, :with_steps, organization: current_organization }
  let(:author) { create :user, :confirmed, organization: current_organization }
  let(:original_attributes) do
    {
      title: generate(:title).dup
    }
  end
  let(:updated_attributes) do
    {
      title: generate(:title).dup
    }
  end
  let(:idea) do
    create(:idea, original_attributes.merge(component: component, users: [author])).tap do |idea|
      trail_state = PaperTrail.config.enabled
      PaperTrail.config.enabled = true
      PaperTrail.request(whodunnit: author.to_gid) do
        idea.update!(updated_attributes)
      end
      PaperTrail.config.enabled = trail_state
    end
  end
  let(:model) { idea.versions.last }

  describe "changeset" do
    let(:query) { "{ changeset }" }

    it "returns the changeset" do
      expect(response["changeset"]["title"]).to eq(
        %W(#{original_attributes[:title]} #{updated_attributes[:title]})
      )
    end
  end

  describe "editor" do
    let(:query) { "{ editor { id name nickname } }" }

    it "returns the editor" do
      expect(response["editor"]["id"]).to eq(author.id.to_s)
      expect(response["editor"]["name"]).to eq(author.name)
      expect(response["editor"]["nickname"]).to eq("@#{author.nickname}")
    end
  end
end
