((exports) => {
  const $ = exports.$;

  /**
   * Configurator for a base map, not specifically related to ideas.
   */
  class MapConfigurator {
    constructor(elementId) {
      this.elementId = elementId;
      this.mapConfiguration = {};
      this.tileLayerConfiguration = {};

      this.$map = $(`#${elementId}`);
      if (this.$map.length < 1) {
        return;
      }

      const reader = this.createConfigurationReader();
      this.mapConfiguration.center = reader.getCenterCoordinates();
      this.mapConfiguration.zoom = reader.getZoomLevel();
      this.mapConfiguration.iconColor = reader.getIconColor();
      this.mapConfiguration.tileLayerConfiguration = reader.getTileLayerConfiguration();
    }

    createConfigurationReader() {
      return new MapConfigurationReader(this.$map);
    }

    getElementId() {
      return this.elementId;
    }

    getMapConfiguration() {
      return this.mapConfiguration;
    }

    getTileLayerConfiguration() {
      return this.tileLayerConfiguration;
    }
  }

  /**
   * Builder for the idea create/edit view map that adds the functionality
   * specific to that map.
   */
  class IdeaMapConfigurator extends MapConfigurator {
    getConnectedInputSelector() {
      const connectedInputSelector = this.$map.data("connected-input");
      if (!connectedInputSelector || connectedInputSelector.length < 1) {
        return null;
      }
      return connectedInputSelector;
    }
  }

  /**
   * A configuration reader that reads the configurations from the parameters
   * available in the view.
   */
  class MapConfigurationReader {
    constructor($map) {
      this.$map = $map;
    }

    getCenterCoordinates() {
      const mapCenter = this.$map.data("center-coordinates");
      let centerLat = 0;
      let centerLng = 0;
      if ($.type(mapCenter) === "string") {
        const mapCenterParts = mapCenter.split(",");
        centerLat = parseFloat(mapCenterParts[0]);
        if (isNaN(centerLat)) {
          centerLat = 0;
        }
        centerLng = parseFloat(mapCenterParts[1]);
        if (isNaN(centerLng)) {
          centerLng = 0;
        }
      }
      return [centerLat, centerLng];
    }

    getZoomLevel() {
      const zoomLevel = this.$map.data("zoom-level");
      if ($.type(zoomLevel) === "string") {
        const zoom = parseInt(zoomLevel);
        if (!isNaN(zoom)) {
          return zoom;
        }
      }
      return 11;
    }

    getIconColor() {
      const iconColor = getComputedStyle(
        document.documentElement
      ).getPropertyValue("--primary");
      if (iconColor && iconColor.length > 0) {
        return iconColor
      }
      return "#ef604d";
    }

    getTileLayerConfiguration() {
      const hereApiKey = this.$map.data("here-api-key");
      if (hereApiKey) {
        return { apiKey: hereApiKey };
      }

      return {
        appId: this.$map.data("here-app-id"),
        appCode: this.$map.data("here-app-code")
      };
    }
  }

  exports.Decidim = exports.Decidim || {};
  exports.Decidim.IdeaMapConfigurationReader = MapConfigurationReader;
  exports.Decidim.IdeaMapConfigurator = IdeaMapConfigurator;
})(window);
