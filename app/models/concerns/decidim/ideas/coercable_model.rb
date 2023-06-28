# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module Ideas
    # A workaround to be able to use Virtus which requires the models to respond
    # to `#to_hash`.
    module CoercableModel
      extend ActiveSupport::Concern

      def to_hash
        attributes
      end
    end
  end
end
