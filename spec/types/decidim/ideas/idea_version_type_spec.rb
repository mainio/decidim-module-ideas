# frozen_string_literal: true

require "spec_helper"
require "decidim/api/test/type_context"

describe Decidim::Ideas::IdeaVersionType, type: :graphql do
  include_context "with a graphql type"

  # let(:schema) { Decidim::Api::Schema }
  let(:type_class) { Decidim::Api::QueryType }
  let(:locale) { "en" }

  let(:organization) { create(:organization) }
  let!(:component) do
    create(:idea_component,
           :with_creation_enabled,
           manifest: manifest,
           participatory_space: participatory_process)
  end
  let!(:participatory_process) { create :participatory_process, :with_steps, organization: organization }
  let(:manifest_name) { "ideas" }
  let(:manifest) { Decidim.find_component_manifest(manifest_name) }
  let!(:idea) { create :idea, component: component }

  let(:query) do
    %(
      {
        participatoryProcess(
          slug: "#{participatory_process.slug}"
        ){
          components{
            ...on Ideas{
              ideas{
                edges{
                  node{
                    id
                    versions{
                      changeset
                    }
                  }
                }
              }
            }
          }
        }
      }
    )
  end

  describe "valid query" do
    it "executes sucessfully" do
      raise response.inspect
      expect { response }.not_to raise_error
    end
  end
end
