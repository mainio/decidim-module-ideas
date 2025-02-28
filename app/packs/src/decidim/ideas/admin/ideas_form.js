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
      $sub.removeClass("hide");
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
        $(".geocoding-field").addClass("hide");
      } else {
        $(".geocoding-field").removeClass("hide");
      }
    }).trigger("change.decidim.ideas");
  };

  const uploadModalCorrection = () => {
    let attachmentButtons = document.querySelectorAll("button[data-upload]");
    attachmentButtons.forEach(function(button) {
      let modal = document.querySelector(`#${button.dataset.dialogOpen}`)
      let files = document.querySelector(`[data-active-uploads=${button.dataset.dialogOpen}]`)
      let options = JSON.parse(button.dataset.upload);
      let attrName = `idea[${options.addAttribute}]`;

      let saveButton = modal.querySelector("button[data-dropzone-save]");
      saveButton.addEventListener("click", function() {
        setTimeout(function() {
          let idx = 0;
          files.querySelectorAll(`input[type="hidden"][name="${attrName}"]`).forEach(function(input) {
            if (input.value && input.value.match(/^[0-9]+$/)) {
              input.setAttribute("name", `${attrName}[${idx}][id]`);
            } else {
              input.setAttribute("name", `${attrName}[${idx}][file]`);
            }

            idx += 1;
          })
        }, 0);
      });
    });
  };

  $(() => {
    bindSubcategoryInputs();
    uploadModalCorrection();
  });
})(window);
