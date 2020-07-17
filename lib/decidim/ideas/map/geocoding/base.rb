# frozen_string_literal: true

module Decidim
  module Ideas
    module Map
      # This module contains all the domain logic associated to Decidim's Ideas
      # component admin panel.
      module Geocoding
        class Base
          def initialize(organization:)
            @organization = organization
          end

          def prepare!
            Geocoder.configure(Geocoder.config.merge(
              http_headers: { "Referer" => organization.host }
            ))
          end

          def search(query, options = {})
            Geocoder.search(query, options)
          end

          def coordinates(address, options = {})
            Geocoder.coordinates(address, options)
          end

          def address(coordinates, options = {})
            results = search(coordinates, options)
            return if results.empty?

            results.sort! do |result1, result2|
              dist1 = Geocoder::Calculations.distance_between(
                result1.coordinates,
                coordinates
              )
              dist2 = Geocoder::Calculations.distance_between(
                result2.coordinates,
                coordinates
              )
              dist1 <=> dist2
            end

            results.first.address
          end

          protected

          attr_accessor :organization
        end
      end
    end
  end
end
