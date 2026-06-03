((exports) => {
  const $ = exports.$; // eslint-disable-line

  const bindTaxonomySelectors = () => {
    $("[data-taxonomy-filter]").each((_i, select) => {
      // pre-populate parent if a child is already selected (edit mode)
      const $filterGroup = $(select).closest("[data-filter-group]");
      $filterGroup.find("[data-parent-taxonomy]").each((_j, div) => {
        const parentId = $(div).data("parent-taxonomy");
        const childVal = $(div).find("select").val();
        if (childVal) {
          $(select).val(parentId);
          $(div).removeClass("hidden");
        }
      });

      $(select).on("change.decidim.ideas", (ev) => {
        hideAllSubTaxonomies(ev.target);
        showSubTaxonomy(ev.target);
      });
    });
  };

  const hideAllSubTaxonomies = (select) => {
    const $filterGroup = $(select).closest("[data-filter-group]");
    $filterGroup.find("[data-parent-taxonomy]").each((_i, div) => {
      $(div).addClass("hidden");
      $(div).find("select").val("");
    });
  };

  const showSubTaxonomy = (select) => {
    const selectedValue = $(select).val();
    if (!selectedValue) return;

    const $subDiv = $(`#sub_taxonomy_${selectedValue}`);
    if ($subDiv.length) {
      $subDiv.removeClass("hidden");
    }
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
    bindTaxonomySelectors();
    uploadModalCorrection();
  });
})(window);