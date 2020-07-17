# frozen_string_literal: true

module Decidim
  module Ideas
    module Map
      class Here < Base
        def configuration
          if Decidim.geocoder[:here_api_key]
            return {
              api_key: Decidim.geocoder[:here_api_key]
            }
          end

          # Compatibility mode for old api_id/app_code configurations
          {
            app_id: Decidim.geocoder[:here_app_id],
            app_code: Decidim.geocoder[:here_app_code]
          }
        end

        def js_map_configure(map_id)
          %{
            var $map = $("##{map_id}");
            $map.on("configure.decidim.ideas", function(_ev, map) {
              var tileLayerConfig = #{js_configuration.to_json};
              L.tileLayer.here(tileLayerConfig).addTo(map);
            });
          }
        end

        protected

        def geocoder_class
          Decidim::Ideas::Map::Geocoding::Here
        end
      end
    end
  end
end
