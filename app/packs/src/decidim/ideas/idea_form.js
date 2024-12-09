import "src/decidim/ideas/reset_inputs";
import "src/decidim/ideas/info_modals";

((exports) => {
  const $ = exports.$; // eslint-disable-line

  // Defines whether the user can exit the view without a warning or not
  let canExit = false;

  const DEFAULT_MESSAGES = {
    charactersUsed: "%count%/%total% characters used",
    charactersMin: "(at least %count characters required)"
  };
  const DEFAULT_OPTIONS = {
    messages: DEFAULT_MESSAGES
  };
  let OPTIONS = DEFAULT_OPTIONS;

  class Options {
    static configure(options) {
      OPTIONS = $.extend(DEFAULT_OPTIONS, options);
    }

    static getMessage(message) {
      return OPTIONS.messages[message];
    }
  }

  class InputCharacterCounter {
    constructor(input, counterElement) {
      this.$input = input;
      this.$target = counterElement;
      this.minCharacters = parseInt(this.$input.attr("minlength"), 10);
      this.maxCharacters = parseInt(this.$input.attr("maxlength"), 10);

      if (this.maxCharacters > 0 || this.minCharacters > 0) {
        this.bindEvents();
      }
    }

    bindEvents() {
      this.$input.on("keyup", () => {
        this.updateStatus();
      });
      this.updateStatus();
    }

    updateStatus() {
      const numCharacters = this.$input.val().length;
      const showMessages = [];

      if (this.maxCharacters > 0) {
        let message = Options.getMessage("charactersUsed");

        showMessages.push(
          message.replace(
            "%count%",
            numCharacters
          ).replace(
            "%total%",
            this.maxCharacters
          )
        );
      }
      if (this.minCharacters > 0 && this.minCharacters > numCharacters) {
        let message = Options.getMessage("charactersMin");

        showMessages.push(
          message.replace(
            "%count%",
            this.minCharacters
          )
        );
      }
      this.$target.html(showMessages.join("<br>"));
    }
  }

  /**
   * In later Foundation versions, this is already handled by Foundation core.
   *
   * This validates the form on submit as it does not work with the Foundation
   * version that currently ships with Decidim.
   * @returns {void}
   */
  const bindFormValidation = () => {
    const $form = $("form.new_idea, form.edit_idea");
    const $submits = $("[type=\"submit\"]", $form);
    const $discardLink = $(".discard-draft-link", $form);

    $submits.
      off("click.decidim.ideas.form").
      on("click.decidim.ideas.form", (ev) => {
        // Tell the backend which submit button was pressed (save or preview)
        let $btn = $(ev.target);
        if (!$btn.is("button")) {
          $btn = $btn.closest("button");
        }

        $form.append(`<input type="hidden" name="save_type" value="${$btn.attr("name")}" />`);
        $submits.attr("disabled", true);

        if (!ev.key || (ev.key === " " || ev.key === "Enter")) {
          ev.preventDefault();

          canExit = true;
          $form.submit();

          const $firstField = $("input.is-invalid-input, textarea.is-invalid-input, select.is-invalid-input").first();
          if ($firstField.length > 0) {
            $firstField.focus();
            $submits.removeAttr("disabled");
          }
        }
      });

    $discardLink.
      off("click.decidim.ideas.form").
      on("click.decidim.ideas.form", () => {
        canExit = true;
      });
  };

  const bindAddressLookup = () => {
    const $map = $("#map");
    const $address = $("#idea_address");
    const $latitude = $("#idea_latitude");
    const $longitude = $("#idea_longitude");
    const authToken = $("input[name=\"authenticity_token\"]").val();
    const coordinatesUrl = $address.data("coordinates-url");
    const addressUrl = $address.data("address-url");

    const performAddressLookup = () => {
      $.ajax({
        method: "POST",
        url: addressUrl,
        data: { authenticity_token: authToken, lat: $latitude.val(), lng: $longitude.val() }, // eslint-disable-line camelcase
        dataType: "json"
      }).done((resp) => {
        if (resp.success) {
          $address.val(resp.result.address);
        }
      });
    };

    const performCoordinatesLookup = () => {
      $.ajax({
        method: "POST",
        url: coordinatesUrl,
        data: { authenticity_token: authToken, address: $address.val() }, // eslint-disable-line camelcase
        dataType: "json"
      }).done((resp) => {
        if (resp.success) {
          $latitude.val(resp.result.lat);
          $longitude.val(resp.result.lng);

          $map.trigger("coordinates.decidim.ideas", [{
            lat: resp.result.lat,
            lng: resp.result.lng
          }]);
        }
      });
    }

    // Prevent the form submit event on keydown event in the address field
    $address.on("keydown.decidim.ideas", (ev) => {
      if (ev.keyCode === 13) {
        ev.preventDefault();
      }
    });
    // Perform lookup only on the keyup event so that we will not perform
    // multiple searches if enter is kept down.
    $address.on("keyup.decidim.ideas", (ev) => {
      if (ev.keyCode === 13) {
        performCoordinatesLookup();
      }
    });
    // The address field can be reset in which case we should also reset the
    // map marker.
    $address.on("change.decidim.ideas", () => {
      if ($address.val() === "") {
        $map.trigger("coordinates.decidim.ideas", [null]);
      }
    });

    // When we receive coordinates from the map, update the relevant coordinate
    // fields and perform address lookup.
    $address.on("coordinates.decidim.ideas", (_ev, coordinates) => {
      $latitude.val(coordinates.lat).attr("value", coordinates.lat);
      $longitude.val(coordinates.lng).attr("value", coordinates.lng);

      performAddressLookup();
    });

    // When we receive the specify event from the map, this means the user moved
    // the marker specifying a more exact position. Update the relevant
    // coordinate fields but do not perform.
    $address.on("specify.decidim.ideas", (_ev, coordinates) => {
      $latitude.val(coordinates.lat).attr("value", coordinates.lat);
      $longitude.val(coordinates.lng).attr("value", coordinates.lng);
    });

    // Listen for the autocompletion event from Tribute
    $address.on("tribute-replaced", (ev) => {
      const selected = ev.detail.item.original;
      if (selected.coordinates) {
        $latitude.val(selected.coordinates[0]).attr("value", selected.coordinates[0]);
        $longitude.val(selected.coordinates[1]).attr("value", selected.coordinates[1]);

        $map.trigger("coordinates.decidim.ideas", [{
          lat: selected.coordinates[0],
          lng: selected.coordinates[1]
        }]);
      } else {
        performCoordinatesLookup();
      }
    });

    $("#address_lookup").on("click.decidim.ideas", (ev) => {
      ev.preventDefault();
      performCoordinatesLookup();
    });

    if ($latitude.val() && $latitude.val().length > 0 && $longitude.val() && $longitude.val().length > 0) {
      $map.trigger("coordinates.decidim.ideas", [{
        lat: $latitude.val(),
        lng: $longitude.val()
      }]);
    }
  };

  const bindSubcategoryInputs = () => {
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
  };

  const bindAccidentalExitDisabling = () => {
    $(document).on("click", "a, input, button", (ev) => {
      const $target = $(ev.target);
      if ($target.closest(".idea-form-container").length > 0) {
        canExit = true;
      } else if ($target.closest("#loginModal").length > 0) {
        canExit = true;
      }
    });

    window.addEventListener("beforeunload", (ev) => {
      if (canExit) {
        return;
      }

      // Confirm exit. Setting this to an empty string would not work in
      // Firefox (although it should according to the spec), so we set it to
      // `true` instead.
      ev.returnValue = true;
    });
  };

  exports.Decidim = exports.Decidim || {};
  exports.DecidimIdeas = exports.DecidimIdeas || {};

  exports.DecidimIdeas.configure = (options) => {
    Options.configure(options);
  };

  exports.DecidimIdeas.bindCharacterCounter = ($input, $message) => {
    const counter = new InputCharacterCounter($input, $message);
    $input.data("characters-counter", counter)
  };

  $(() => {
    bindFormValidation();
    bindAddressLookup();
    bindSubcategoryInputs();
    bindAccidentalExitDisabling();
  });
})(window);
