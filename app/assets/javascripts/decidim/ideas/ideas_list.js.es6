(() => {
  $(() => {
    const $form = $('form.new_filter');

    $form.on("reset.ideas", (_ev) => {
      $('input[type="search"]').trigger("change");
    });
  });
})(window);
