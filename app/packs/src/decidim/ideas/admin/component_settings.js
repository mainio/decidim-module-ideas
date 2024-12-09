$(() => {
  const $coordinatesElement = $(".area_scope_coordinates_container");

  const handleParentAreaScopeChange = (ev) => {
    const scopeId = $(ev.target).val();
    const updateUrl = $coordinatesElement.data("update-url");
    const settingName = $coordinatesElement.data("setting-name");

    $.ajax({
      method: "GET",
      url: updateUrl,
      data: {parent_scope_id: scopeId, setting_name: settingName}// eslint-disable-line camelcase
    }).done((data) => {
      $(".area-scope-coordinates", $coordinatesElement).replaceWith(data);
    });
  };

  $("input[name='component[settings][geocoding_enabled]']").on("change", (ev) => {
    if ($(ev.target).is(":checked")) {
      $coordinatesElement.removeClass("hidden");
    } else {
      $coordinatesElement.addClass("hidden");
    }
  });

  $(document).on(
    "change",
    "input[name='component[settings][area_scope_parent_id]']",
    handleParentAreaScopeChange
  );
});
