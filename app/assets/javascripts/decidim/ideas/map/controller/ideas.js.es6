((exports) => {
  // const L = exports.L; // eslint-disable-line

  exports.Decidim = exports.Decidim || {};

  const MapMarkersController = exports.Decidim.MapMarkersController;

  class IdeasMapController extends MapMarkersController {
    start() {
      this.markerClusters = null;

      let markersWithLocation = [];
      if (Array.isArray(this.config.markers)) {
        markersWithLocation = this.config.markers.filter((marker) => marker.latitude && marker.longitude);
      }

      if (markersWithLocation.length > 0) {
        this.addMarkers(this.config.markers);

        if (this.config.markers.length < 10) {
          this.map.setZoom(10);
        }
      } else if (Array.isArray(this.config.centerCoordinates) && this.config.centerCoordinates.length > 1) {
        this.map.panTo(this.config.centerCoordinates);
        this.map.setZoom(10);
      } else {
        this.map.fitWorld();
        this.map.panTo([0, 0]);
        this.map.setZoom(1)
      }
    }
  }

  exports.Decidim.IdeasMapController = IdeasMapController;
})(window);
