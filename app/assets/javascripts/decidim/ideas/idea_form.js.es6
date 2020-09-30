// = require decidim/ideas/reset_inputs
// = require decidim/ideas/info_modals

((exports) => {
  const $ = exports.$; // eslint-disable-line

  const DEFAULT_MESSAGES = {
    charactersUsed: "%count%/%total% characters used"
  };
  const DEFAULT_OPTIONS = {
    messages: DEFAULT_MESSAGES
  };
  let OPTIONS = DEFAULT_OPTIONS;

  class Options {
    static configure(options) {
      OPTIONS = exports.$.extend(DEFAULT_OPTIONS, options);
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

      console.log(this.$target);

      this.$target.text(showMessages.join(", "));
    }
  }

  /**
   * In later Foundation versions, this is already handled by Foundation core.
   *
   * This validates the form on submit as it does not work with the Foundation
   * version that currently ships with Decidin.
   */
  const bindFormValidation = () => {
    const $form = exports.$("form.new_idea");
    const $submits = exports.$(`[type="submit"]`, $form);

    $submits
      .off('click.decidim.ideas.form')
      .on('click.decidim.ideas.form', (e) => {
        if (!e.key || (e.key === ' ' || e.key === 'Enter')) {
          e.preventDefault();
          $form.submit();

          const $firstField = $("input.is-invalid-input, textarea.is-invalid-input").first();
          $firstField.focus();
        }
      });
  };

  const bindAddressLookup = () => {
    const $map = exports.$("#map");
    const $address = exports.$("#idea_address");
    const $latitude = exports.$("#idea_latitude");
    const $longitude = exports.$("#idea_longitude");
    const authToken = $(`input[name="authenticity_token"]`).val();
    const coordinatesUrl = $address.data("coordinates-url");
    const addressUrl = $address.data("address-url");

    const performAddressLookup = () => {
      $.ajax({
        method: "POST",
        url: addressUrl,
        data: { authenticity_token: authToken, lat: $latitude.val(), lng: $longitude.val() },
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
        data: { authenticity_token: authToken, address: $address.val() },
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
      if (ev.keyCode == 13) {
        ev.preventDefault();
      }
    });
    // Perform lookup only on the keyup event so that we will not perform
    // multiple searches if enter is kept down.
    $address.on("keyup.decidim.ideas", (ev) => {
      if (ev.keyCode == 13) {
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

    if ($latitude.val().length > 0 && $longitude.val().length > 0) {
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
  };

  const bindAttachmentModals = () => {
    // The attachment fields need to be inside the form when it is submitted but
    // the reveal is displayed outside of the form. Therefore, we move the
    // fields to the reveal when it is opened and back to the form when it is
    // closed.
    $("#image-modal, #attachment-modal").on("open.zf.reveal", (ev) => {
      const $reveal = $(ev.target);
      const $button = $(`button[data-open='${$reveal.attr("id")}']`);
      const $buttonWrapper = $button.parent();
      const $fields = $(".attachment-fields", $buttonWrapper);

      $(".reveal__content", $reveal).append($fields);
    });
    $("#image-modal, #attachment-modal").on("closed.zf.reveal", (ev) => {
      const $reveal = $(ev.target);
      const $button = $(`button[data-open='${$reveal.attr("id")}']`);
      const $buttonWrapper = $button.parent();
      const $fields = $(".attachment-fields", $reveal);

      $buttonWrapper.append($fields);
    });

    $(".add-attachment").on("click", (ev) => {
      // Sometimes the form is submitted in case the event is not prevented.
      ev.preventDefault();

      const $reveal = $(ev.target).closest(".reveal");
      const $file = $("input[type='file']", $reveal);
      const $text = $("input[type='text']", $reveal);
      const $fields = $(".attachment-fields", $reveal);
      const filePresent = $fields.data("file-present");

      $(".form-error-general", $reveal).removeClass("is-visible");

      let success = true;
      if ($file.get(0).files.length === 0 && !filePresent) {
        success = false;
        $(".form-error-general", $file.closest(".field")).addClass("is-visible");
      }
      if ($.trim($text.val()).length < 1) {
        success = false;
        $(".form-error-general", $text.closest(".field")).addClass("is-visible");
      }

      if (success) {
        const $button = $(`button[data-open='${$reveal.attr("id")}']`);
        const $buttonWrapper = $button.parent();

        $reveal.foundation("close");
        $(".attachment-added", $buttonWrapper).removeClass("hide");
      }
    });

    $(".cancel-attachment").on("click", (ev) => {
      const $reveal = $(ev.target).closest(".reveal");
      const $file = $("input[type='file']", $reveal);
      const $text = $("input[type='text']", $reveal);

      $(".form-error-general", $reveal).removeClass("is-visible");

      // In case of an error, make sure the fields are cleared.
      if ($file.get(0).files.length === 0 || $.trim($text.val()).length < 1) {
        const $button = $(`button[data-open='${$reveal.attr("id")}']`);
        const $buttonWrapper = $button.parent();

        $file.replaceWith($file.val("").clone(true));
        $text.val("");
        $(".attachment-added", $buttonWrapper).addClass("hide");
      }
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
    bindAttachmentModals();
  });
})(window);
