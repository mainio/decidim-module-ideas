# frozen_string_literal: true

require "spec_helper"

describe Decidim::Ideas::AdminLog::IdeaPresenter, type: :helper do
  include_examples "present admin log entry" do
    let(:participatory_space) { create(:participatory_process, organization:) }
    let(:component) { create(:idea_component, participatory_space:) }
    let(:admin_log_resource) { create(:idea, component:) }
    let(:action) { "answer" }
  end
end
