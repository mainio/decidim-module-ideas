# frozen_string_literal: true

module Decidim
  module Ideas
    class GeocodingsController < Decidim::Ideas::ApplicationController
      include Decidim::ApplicationHelper

      before_action :prepare_geocoder, only: [:new, :reverse]

      def create
        enforce_permission_to :create, :idea

        headers["X-Robots-Tag"] = "none"

        coordinates = geocoder.coordinates(params[:address])

        if coordinates.present?
          render json: {
            success: true,
            result: { lat: coordinates.first, lng: coordinates.last }
          }
        else
          render json: {
            success: false,
            result: { }
          }
        end
      end

      def reverse
        enforce_permission_to :create, :idea

        headers["X-Robots-Tag"] = "none"

        address = geocoder.address([params[:lat], params[:lng]])

        if address.present?
          render json: {
            success: true,
            result: { address: address }
          }
        else
          render json: {
            success: false,
            result: { }
          }
        end
      end

      private

      def prepare_geocoder
        geocoder.prepare!
      end

      def geocoder
        @geocoder ||= Decidim::Ideas.geocoding_utility.new(
          organization: current_organization
        )
      end
    end
  end
end
