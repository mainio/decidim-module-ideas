((exports) => {
  const $ = exports.$; // eslint-disable-line

  const bindSubcategoryInputs = () => {
    const $geocodingToggle = $("#idea_perform_geocoding");
    const $subcategories = $("#idea-subcategory");
    const $sections = $(".subcategories", $subcategories);
    $subcategories.html("");

    const subcategorySelects = {};
    $sections.each((_i, el) => {
      const $sub = $(el);
      $sub.removeClass("hidden");
      subcategorySelects[$sub.data("parent")] = $sub;
    });

    $("#idea_category_id").on("change.decidim.ideas", (ev) => {
      const $cat = $(ev.target);
      const parentId = $cat.val();

      $subcategories.html("");

      const $sub = subcategorySelects[parentId];
      if ($sub) {
        $subcategories.append($sub);
      }
    }).trigger("change.decidim.ideas");

    $geocodingToggle.on("change.decidim.ideas", () => {
      if ($geocodingToggle.is(":checked")) {
        $(".geocoding-field").addClass("hidden");
      } else {
        $(".geocoding-field").removeClass("hidden");
      }
    }).trigger("change.decidim.ideas");
  };

  $(() => {
    bindSubcategoryInputs();
  });
})(window);
