# frozen_string_literal: true

module Decidim
  module Ideas
    # This module contains all the utilities for the geocoding services.
    module Geocoding
      autoload :Base, "decidim/ideas/geocoding/base"
      autoload :Here, "decidim/ideas/geocoding/here"
    end
  end
end
