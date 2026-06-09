# frozen_string_literal: true

module Decidim
  module Ideas
    class InfoController < Decidim::Ideas::ApplicationController
      include Decidim::ApplicationHelper

      def show
        @intro, @text =
          case params[:section]
          when "terms"
            [
              translated_attribute(component_settings.terms_intro),
              translated_attribute(component_settings.terms_text)
            ]
          else
            raise ActionController::RoutingError, "Not found"
          end

        headers["X-Robots-Tag"] = "none"

        respond_to do |format|
          format.html
          format.json { render json: { intro: @intro, text: @text } }
        end
      end
    end
  end
end
