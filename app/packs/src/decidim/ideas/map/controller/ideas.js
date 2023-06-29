import MapMarkersController from "src/decidim/map/controller/markers";

export default class IdeasMapController extends MapMarkersController {
  start() {
    this.markerClusters = null;

    let markersWithLocation = [];
    if (Array.isArray(this.config.markers)) {
      markersWithLocation = this.config.markers.filter((marker) => marker.latitude && marker.longitude);
    }

    if (markersWithLocation.length > 0) {
      this.addMarkers(markersWithLocation);

      if (this.config.markers.length < 10) {
        this.map.setZoom(10);
      }
    } else {
      this.map.fitWorld();

      if (Array.isArray(this.config.centerCoordinates) && this.config.centerCoordinates.length > 1) {
        this.map.setZoom(10);
        this.map.panTo(this.config.centerCoordinates);
      } else {
        this.map.setZoom(1)
        this.map.panTo([0, 0]);
      }
    }
  }
}
