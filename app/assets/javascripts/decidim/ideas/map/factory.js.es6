// = require decidim/ideas/map/controller/idea_form
// = require_self

((exports) => {
  exports.Decidim = exports.Decidim || {};

  const coreCreateMapController = exports.Decidim.createMapController;
  const IdeaFormMapController = exports.Decidim.IdeaFormMapController;

  const createMapController = (mapId, config) => {
    if (config.type === "idea-form") {
      return new IdeaFormMapController(mapId, config);
    }

    return coreCreateMapController(mapId, config);
  }

  exports.Decidim.createMapController = createMapController;
})(window);
