# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module Ideas
    module Admin
      module Picker
        extend ActiveSupport::Concern

        included do
          helper Decidim::Ideas::Admin::IdeasPickerHelper
        end

        def ideas_picker
          render :ideas_picker, layout: false
        end
      end
    end
  end
end
