# frozen_string_literal: true

module Decidim
  module Ideas
    # This module contains all the utilities for the maps and geocoding
    # services.
    module Map
      autoload :Base, "decidim/ideas/map/base"
      autoload :Here, "decidim/ideas/map/here"

      # This module contains all the utilities for the geocoding services.
      module Geocoding
        autoload :Base, "decidim/ideas/map/geocoding/base"
        autoload :Here, "decidim/ideas/map/geocoding/here"
      end
    end
  end
end
