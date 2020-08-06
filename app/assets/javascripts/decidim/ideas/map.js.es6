// = require decidim/ideas/map/factory

((exports) => {
  const $ = exports.$; // eslint-disable-line

  $("[data-decidim-map]").on("ready.decidim", (ev, _map, mapConfig) => {
    const $map = $(ev.target);
    const ctrl = $map.data("map-controller");

    // If it's an idea form map, bind the connected input with the map events
    // and send the coordinates from the input to the map when received.
    if (mapConfig.type === "idea-form") {
      const $connectedInput = $($map.data("connected-input"));

      // The map triggers a "coordinates" event when the marker is placed on
      // the map. This sends the coordinates to the connected input.
      ctrl.setEventHandler("coordinates", (latlng) => {
        $connectedInput.trigger("coordinates.decidim.ideas", [latlng]);
      });

      // The map triggers a "specify" event when an existing marker is moved on
      // the map. This sends the coordinates to the connected input for update.
      ctrl.setEventHandler("specify", (latlng) => {
        $connectedInput.trigger("specify.decidim.ideas", [latlng]);
      });

      // The input can trigger a "coordinates" event on the map element meaning
      // that the user searched for an address which returned a map point which
      // should be placed on the map.
      $map.on("coordinates.decidim.ideas", (_ev, coordinates) => {
        if (coordinates === null) {
          // When the coordinates is null, the marker should be removed if it
          // exists.
          ctrl.removeMarker();
          return;
        }

        ctrl.receiveCoordinates(coordinates.lat, coordinates.lng);
      });
    }
  });
})(window);
