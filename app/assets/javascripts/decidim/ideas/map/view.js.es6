// = require leaflet
// = require leaflet-tilelayer-here
// = require leaflet-svg-icon
// = require decidim/ideas/map/icon

((exports) => {
  exports.Decidim = exports.Decidim || {};

  const $ = exports.$;
  const Leaflet = exports.L;
  const MapIcon = exports.Decidim.IdeaMapIcon;

  const DEFAULT_OPTIONS = {
    iconColor: "#ef604d",
    center: [0, 0],
    zoom: 11,
    eventNameSuffix: ".decidim.ideas",
    eventNames: {
      configure: "configure",
      coordinates: "coordinates",
      specify: "specify",
    },
  }

  /**
   * View for a base map, not specifically related to ideas.
   */
  class MapView {
    constructor(elementId, options) {
      this.element = document.getElementById(elementId);
      this.options = $.extend(true, {}, DEFAULT_OPTIONS, options);

      this.map = Leaflet.map(elementId, {
        center: options.center,
        zoom: options.zoom
      });

      this.map.scrollWheelZoom.disable();

      $(this.element).trigger(this.getEventName("configure"), [this.map]);
    }

    createIcon() {
      return new MapIcon({
        fillColor: this.options.iconColor,
        iconSize: Leaflet.point(28, 36)
      });
    }

    getMap() {
      return this.map;
    }

    getElement() {
      return this.element;
    }

    getEventName(baseName) {
      if (baseName in this.options.eventNames) {
        baseName = this.options.eventNames[baseName];
      }

      return `${baseName}${this.options.eventNameSuffix}`;
    }

    addTileLayer(configuration) {
      Leaflet.tileLayer.here(configuration).addTo(this.map);
    }
  }

  /**
   * View for the idea create/edit view map that adds the functionality
   * specific to that map.
   */
  class IdeaMapView extends MapView {
    constructor(elementId, options) {
      super(elementId, options);

      this.marker = null;
      this.$connectInput = null;

      $(this.element).on(
        this.getEventName("coordinates"),
        (_ev, coordinates) => {
          if (coordinates === null) {
            // When the coordinates is null, the marker should be removed if it
            // exists.
            if (this.marker) {
              this.marker.remove();
              this.marker = null;
            }
            return;
          }

          this.addOrMoveMarker(coordinates.lat, coordinates.lng);
          this.map.panTo([coordinates.lat, coordinates.lng]);
        }
      );

      this.map.on("click", (ev) => {
        this.addOrMoveMarker(ev.latlng.lat, ev.latlng.lng);

        if (this.$connectInput === null) {
          return;
        }

        this.$connectInput.trigger(this.getEventName("coordinates"), [{
          lat: ev.latlng.lat,
          lng: ev.latlng.lng
        }]);
      });
    }

    connectInput(inputSelector) {
      this.$connectInput = $(inputSelector);
    }

    addOrMoveMarker(latitude, longitude) {
      if (this.$connectedInput === null) {
        return null;
      }

      if (this.marker) {
        this.marker.setLatLng([latitude, longitude]);
      } else {
        this.marker = Leaflet.marker([latitude, longitude], {
          icon: this.createIcon(),
          draggable: true
        }).addTo(this.map);
        this.marker.on("move", (ev) => {
          if (this.$connectInput === null) {
            return;
          }

          this.$connectInput.trigger(
            this.getEventName("specify"),
            [{
              lat: ev.latlng.lat,
              lng: ev.latlng.lng
            }]
          );
        });
      }

      return this.marker;
    }
  }

  exports.Decidim.IdeaMapView = IdeaMapView;
})(window);
