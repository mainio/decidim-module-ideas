import IdeasMapController from "src/decidim/ideas/map/controller/ideas";
import IdeaFormMapController from "src/decidim/ideas/map/controller/idea_form";

const createMapController = (mapId, config) => {
  if (config.type === "idea-form") {
    return new IdeaFormMapController(mapId, config);
  }

  return new IdeasMapController(mapId, config);
}

window.Decidim.createMapController = createMapController;
