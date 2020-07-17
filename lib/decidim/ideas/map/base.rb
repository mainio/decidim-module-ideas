# frozen_string_literal: true

module Decidim
  module Ideas
    module Map
      class Base
        def initialize(organization:)
          @organization = organization
        end

        def configuration
          {}
        end

        def js_configuration
          configuration.map do |key, value|
            [key.to_s.camelize(:lower), value]
          end.to_h
        end

        def js_map_configure(map_id)
          ""
        end

        def geocoder
          @geocoder ||= geocoder_class.new(organization: organization)
        end

        protected

        attr_accessor :organization

        def geocoder_class
          Decidim::Ideas::Geocoding::Base
        end
      end
    end
  end
end
