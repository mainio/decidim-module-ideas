// = require decidim/ideas/map/view

((exports) => {
  exports.Decidim = exports.Decidim || {};

  const Decidim = exports.Decidim;

  /**
   * Builder for a base map, not specifically related to ideas.
   */
  class MapBuilder {
    constructor(configurator) {
      this.configurator = configurator
    }

    buildMapView() {
      return new Decidim.IdeaMapView(
        this.configurator.getElementId(),
        this.configurator.getMapConfiguration()
      );
    }
  }

  /**
   * Builder for the idea create/edit view map that adds the functionality
   * specific to that map.
   */
  class IdeaMapBuilder extends MapBuilder {
    buildMapView() {
      const view = super.buildMapView();

      const connectedInputSel = this.configurator.getConnectedInputSelector();
      if (connectedInputSel !== null) {
        view.connectInput(connectedInputSel);
      }

      return view;
    }
  }

  exports.Decidim.IdeaMapBuilder = IdeaMapBuilder;
})(window);
