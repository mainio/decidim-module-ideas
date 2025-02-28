# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Ideas
    describe IdeaForm do
      let(:params) do
        super.merge(
          user_group_id:
        )
      end

      it_behaves_like "a idea form", user_group_check: true, i18n: false
    end
  end
end
