// = require decidim/ideas/map/configurator
// = require decidim/ideas/map/builder
// = require_self

((exports) => {
  exports.Decidim = exports.Decidim || {};

  const MapBuilder = exports.Decidim.IdeaMapBuilder;
  const MapConfigurator = exports.Decidim.IdeaMapConfigurator;

  exports.$(() => {
    const mapId = "map";
    const $map = exports.$(`#${mapId}`);

    if ($map.length > 0) {
      // Build the map and define it for the element data
      const configurator = new MapConfigurator(mapId);
      const builder = new MapBuilder(configurator);
      $map.data("map-view", builder.buildMapView());
    }
  });
})(window);
