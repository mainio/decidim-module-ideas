// = require leaflet
// = require leaflet-tilelayer-here
// = require leaflet-svg-icon
// = require jquery-tmpl
// = require_self

((exports) => {
  L.DivIcon.SVGIcon.DecidimIcon = L.DivIcon.SVGIcon.extend({
    options: {
      fillColor: "#ef604d",
      opacity: 0
    },
    _createPathDescription: function() {
      return "M14 1.17a11.685 11.685 0 0 0-11.685 11.685c0 11.25 10.23 20.61 10.665 21a1.5 1.5 0 0 0 2.025 0c0.435-.435 10.665-9.81 10.665-21A11.685 11.685 0 0 0 14 1.17Zm0 17.415A5.085 5.085 0 1 1 19.085 13.5 5.085 5.085 0 0 1 14 18.585Z";
    },
    _createCircle: function() {
      return ""
    },
    // Improved version of the _createSVG, essentially the same as in later
    // versions of Leaflet. It adds the `px` values after the width and height
    // CSS making the focus borders work correctly across all browsers.
    _createSVG: function() {
      const path = this._createPath();
      const circle = this._createCircle();
      const text = this._createText();
      const className = `${this.options.className}-svg`;

      const style = `width:${this.options.iconSize.x}px; height:${this.options.iconSize.y}px;`;

      const svg = `<svg xmlns="http://www.w3.org/2000/svg" version="1.1" class="${className}" style="${style}">${path}${circle}${text}</svg>`;

      return svg;
    }
  });

  const loadMap = ($map, options) => {
    if (exports.Decidim.currentMap) {
      exports.Decidim.currentMap.remove();
      exports.Decidim.currentMap = null;
    }

    const map = L.map($map.attr("id"), {
      center: options.center,
      zoom: options.zoom
    });
    const $connectedInput = options.connectedInput;

    let marker = null;
    const addOrMoveMarker = (latitude, longitude) => {
      if ($connectedInput === null) {
        return null;
      }

      const lat = latitude;
      const lng = longitude;

      if (marker) {
        marker.setLatLng([lat, lng]);
      } else {
        marker = L.marker([lat, lng], {
          icon: new L.DivIcon.SVGIcon.DecidimIcon({
            fillColor: window.Decidim.mapConfiguration.markerColor,
            iconSize: L.point(28, 36)
          }),
          draggable: true
        }).addTo(map);
        marker.on("move", (ev) => {
          $connectedInput.trigger("specify.decidim-ideas", [{
            lat: ev.latlng.lat,
            lng: ev.latlng.lng
          }]);
        });
      }

      return marker;
    }

    $map.on("coordinates.decidim-ideas", (_ev, coordinates) => {
      if (coordinates === null) {
        // When the coordinates is null, the marker should be removed if it
        // exists.
        if (marker) {
          marker.remove();
          marker = null;
        }
        return;
      }

      addOrMoveMarker(coordinates.lat, coordinates.lng);
      map.panTo([coordinates.lat, coordinates.lng]);
    });

    L.tileLayer.here(exports.Decidim.mapConfiguration).addTo(map);

    map.scrollWheelZoom.disable();

    // Fix the keyboard navigation on the map
    map.on("popupopen", (ev) => {
      const $popup = $(ev.popup.getElement());
      $popup.attr("tabindex", 0).focus();
    });
    map.on("popupclose", (ev) => {
      $(ev.popup._source._icon).focus();
    });
    map.on("click", function(ev) {
      addOrMoveMarker(ev.latlng.lat, ev.latlng.lng);

      if ($connectedInput === null) {
        return
      }

      $connectedInput.trigger("coordinates.decidim-ideas", [{
        lat: ev.latlng.lat,
        lng: ev.latlng.lng
      }]);
   });

    return map;
  };

  window.Decidim = window.Decidim || {};

  window.Decidim.loadMap = loadMap;
  window.Decidim.currentMap =  null;
  window.Decidim.mapConfiguration = {};

  exports.$(() => {
    const mapId = "map";
    const $map = exports.$(`#${mapId}`);

    const hereAppId = $map.data("here-app-id");
    const hereAppCode = $map.data("here-app-code");
    const hereApiKey = $map.data("here-api-key");

    const mapCenter = $map.data("center-coordinates");
    let centerLat = 0;
    let centerLng = 0;
    if (exports.$.type(mapCenter) === "string") {
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

    let mapZoom = 11;
    const mapZoomLevel = $map.data("zoom-level");
    if (exports.$.type(mapZoomLevel) === "string") {
      mapZoom = parseInt(mapZoomLevel);
      if (isNaN(mapZoom)) {
        mapZoom = 11;
      }
    }

    let markerColor = getComputedStyle(document.documentElement).getPropertyValue("--primary");
    if (!markerColor || markerColor.length < 1) {
      markerColor = "#ef604d";
    }

    let mapApiConfig = null;
    if (hereApiKey) {
      mapApiConfig = { apiKey: hereApiKey };
    } else {
      mapApiConfig = {
        appId: hereAppId,
        appCode: hereAppCode
      };
    }

    const connectedInputSelector = $map.data("connected-input");
    let $connectedInput = null;
    if (connectedInputSelector && connectedInputSelector.length > 0) {
      $connectedInput = exports.$(connectedInputSelector);
      if ($connectedInput.length < 1) {
        $connectedInput = null;
      }
    }

    window.Decidim.mapConfiguration = $.extend({
      markerColor: markerColor
    }, mapApiConfig);

    if ($map.length > 0) {
      window.Decidim.currentMap = loadMap($map, {
        center: [centerLat, centerLng],
        zoom: mapZoom,
        connectedInput: $connectedInput
      });
    }
  });
})(window);
