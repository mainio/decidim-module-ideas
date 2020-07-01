# frozen_string_literal: true

module Decidim
  module Ideas
    # Geocoding functionality specific to the HERE geocoding service.
    module Geocoding
      class Here < Base
        def address(coordinates, options = {})
          # Pass in a radius of 50 meters as an extra attribute for the HERE
          # API. Also sort the results by distance and pass a maxresults
          # attribute of 5.
          results = search(coordinates + [50], {
            params: {
              sortby: :distance,
              maxresults: 5
            }
          }.merge(options))
          return if results.empty?

          # Always prioritize house number results, even if they are not as
          # close as street level matches.
          hn_result = results.find { |r| r.data["MatchLevel"] == "houseNumber" }
          return hn_result.address if hn_result

          # Some of the matches that have "MatchLevel" == "street" do not even
          # contain the street name unless they also have the "Street" key in
          # the "MatchQuality" attribute defined.
          street_result = results.find { |r| r.data["MatchQuality"].has_key?("Street") }
          return street_result.address if street_result

          # Otherwise, sort the results based on their exact distances from the
          # given coordinates (default functionality).
          results.sort! do |result1, result2|
            # If neither result houseNumber, calculate the distance between
            # the points.
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
      end
    end
  end
end
