$(() => {
  const $coordinatesElement = $(".area_scope_coordinates_container");

  const handleParentTaxonomyFilterChange = (ev) => {
    const filterId = $(ev.target).val();
    const updateUrl = $coordinatesElement.data("update-url");
    const settingName = $coordinatesElement.data("setting-name");

    $.ajax({
      method: "GET",
      url: updateUrl,
      data: { taxonomy_filter_id: filterId, setting_name: settingName }// eslint-disable-line camelcase
    }).done((data) => {
      $(".area-scope-coordinates", $coordinatesElement).replaceWith(data);
    });
  };

  $("input[name='component[settings][geocoding_enabled]']").on("change", (ev) => {
    if ($(ev.target).is(":checked")) {
      $coordinatesElement.removeClass("hide");
    } else {
      $coordinatesElement.addClass("hide");
    }
  });

  $(document).on(
    "change",
    "select[name='component[settings][area_taxonomy_filter_id]']",
    handleParentTaxonomyFilterChange
  );
});
