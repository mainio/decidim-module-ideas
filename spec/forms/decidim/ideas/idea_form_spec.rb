# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Ideas
    describe IdeaForm do
      it_behaves_like "a idea form", i18n: false
    end
  end
end
