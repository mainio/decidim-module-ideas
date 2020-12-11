((exports) => {
  const $ = exports.$; // eslint-disable-line

  const initializePickers = ($parent) => {
    $("[data-idea-picker-form]", $parent).each((_i, el) => {
      const $target = $(el);
      const $form = $(`#${$target.data("idea-picker-form")}`);
      const $selected = $(`#${$target.data("idea-picker-selected")}`);
      const $selectedNumber = $(".accordion-title span", $selected.parent(".accordion-item"));
      const fieldName = $(".sample-idea-field", $selected).attr("name");
      const pickerPath = $target.data("picker-path");
      let selectedIdeas = [];

      $(".sample-idea-field", $selected).remove();

      $(".ideas-picker-item", $selected).each((_j, el) => {
        selectedIdeas.push($(el).data("idea-id"));
      });

      let jqxhr = null;
      let filterTimeout = null;
      const initializeList = ($list) => {
        $(".ideas-picker-chooser", $list).each((_j, el) => {
          const $chooser = $(el);
          const $item = $(".ideas-picker-item", $chooser);

          if (selectedIdeas.includes($item.data("idea-id"))) {
            $chooser.addClass("selected");
          }
        });

        $(".ideas-picker-chooser", $list).on("click", (ev) => {
          ev.preventDefault();

          let $chooser = $(ev.target);
          if (!$chooser.is(".ideas-picker-chooser")) {
            $chooser = $chooser.parents(".ideas-picker-chooser");
          }

          const $item = $(".ideas-picker-item", $chooser);
          const ideaId = $item.data("idea-id");

          if ($chooser.hasClass("selected")) {
            $chooser.removeClass("selected");
            selectedIdeas = selectedIdeas.filter((id) => id !== ideaId);
            $(`[data-idea-id="${ideaId}"], input[value="${ideaId}"]`, $selected).remove();
          } else {
            const $cloneItem = $item.clone();

            $chooser.addClass("selected");
            selectedIdeas.push(ideaId);
            $selected.append($cloneItem);
            $selected.append(`<input type="hidden" name="${fieldName}" value="${ideaId}" class="idea-field">`);

            $(".idea-picker-item-remove", $cloneItem).on("click", (evr) => {
              evr.preventDefault();

              $chooser.trigger("click");
            });
          }

          $selectedNumber.text(selectedIdeas.length);

          $chooser.blur();
        });
      };
      const filterIdeas = () => {
        clearTimeout(filterTimeout);
        filterTimeout = setTimeout(() => {
          if (jqxhr !== null) {
            jqxhr.abort();
          }

          $target.html("<div class='loading-spinner'></div>")
          $.ajax({
            url: pickerPath,
            data: {
              layout: "inline",
              q: $("input[name='ideas_filter[search_text]']", $form).val(),
              activity: $("input[name='ideas_filter[activity]']:checked", $form).val(),
              area_scope: $("select[name='ideas_filter[area_scope_id]']", $form).val(),
              category: $("select[name='ideas_filter[category_id]']", $form).val()
            }
          }).done((data) => {
            $target.html(data);
            initializeList($target);
            jqxhr = null;
          });
        }, 300);
      };
      const resetFilterForm = () => {
        $("select", $form).val("");
        $("input[type='search']", $form).val("");
        $("input[name='ideas_filter[activity]'][value='all']").prop("checked", true);
      };

      $("input[type='radio'], select", $form).on("change", () => {
        filterIdeas();
      });
      $("button", $form).on("click", (ev) => {
        ev.preventDefault();

        if ($(ev.target).attr("type") === "reset") {
          resetFilterForm();
        } else {
          filterIdeas();
        }
      });
      $("input[type='search']", $form).on("search", (ev) => {
        if ($(ev.target).val() === "") {
          filterIdeas();
        }
      });

      initializeList($target);
    });
  };

  $(() => {
    $(".ideas-picker-inline").each((_i, el) => {
      initializePickers($(el));
    });
  });
})(window);
