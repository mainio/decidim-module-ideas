// = require_self
$(document).ready(function () {
  let selectedIdeasCount = function() {
    return $(".table-list .js-check-all-idea:checked").length
  }

  let selectedIdeasNotPublishedAnswerCount = function() {
    return $(".table-list [data-published-state=false] .js-check-all-idea:checked").length
  }

  window.selectedIdeasCountUpdate = function() {
    const selectedIdeas = selectedIdeasCount();
    const selectedIdeasNotPublishedAnswer = selectedIdeasNotPublishedAnswerCount();
    if (selectedIdeas === 0) {
      $("#js-selected-ideas-count").text("")
    } else {
      $("#js-selected-ideas-count").text(selectedIdeas);
    }

    if (selectedIdeas >= 2) {
      $('button[data-action="merge-ideas"]').parent().show();
    } else {
      $('button[data-action="merge-ideas"]').parent().hide();
    }

    if (selectedIdeasNotPublishedAnswer > 0) {
      $('button[data-action="publish-answers"]').parent().show();
      $("#js-form-publish-answers-number").text(selectedIdeasNotPublishedAnswer);
    } else {
      $('button[data-action="publish-answers"]').parent().hide();
    }
  }

  let showBulkActionsButton = function() {
    if (selectedIdeasCount() > 0) {
      $("#js-bulk-actions-button").removeClass("hide");
    }
  }

  window.hideBulkActionsButton = function(force = false) {
    if (selectedIdeasCount() === 0 || force === true) {
      $("#js-bulk-actions-button").addClass("hide");
      $("#js-bulk-actions-dropdown").removeClass("is-open");
    }
  }

  window.showOtherActionsButtons = function() {
    $("#js-other-actions-wrapper").removeClass("hide");
  }

  window.hideOtherActionsButtons = function() {
    $("#js-other-actions-wrapper").addClass("hide");
  }

  window.hideBulkActionForms = function() {
    $(".js-bulk-action-form").addClass("hide");
  }

  if ($(".js-bulk-action-form").length) {
    window.hideBulkActionForms();
    $("#js-bulk-actions-button").addClass("hide");

    $("#js-bulk-actions-dropdown ul li button").click(function(ev) {
      ev.preventDefault();
      let action = $(ev.target).data("action");

      if (action) {
        $(`#js-form-${action}`).submit(function() {
          $(".layout-content > .callout-wrapper").html("");
        })

        $(`#js-${action}-actions`).removeClass("hide");
        window.hideBulkActionsButton(true);
        window.hideOtherActionsButtons();
      }
    })

    // select all checkboxes
    $(".js-check-all").change(function(ev) {
      $(".js-check-all-idea").prop("checked", $(ev.target).prop("checked"));

      if ($(ev.target).prop("checked")) {
        $(".js-check-all-idea").closest("tr").addClass("selected");
        showBulkActionsButton();
      } else {
        $(".js-check-all-idea").closest("tr").removeClass("selected");
        window.hideBulkActionsButton();
      }

      window.selectedIdeasCountUpdate();
    });

    // idea checkbox change
    $(".table-list").on("change", ".js-check-all-idea", function (ev) {
      let ideaId = $(ev.target).val()
      let checked = $(ev.target).prop("checked")

      // uncheck "select all", if one of the listed checkbox item is unchecked
      if ($(ev.target).prop("checked") === false) {
        $(".js-check-all").prop("checked", false);
      }
      // check "select all" if all checkbox ideas are checked
      if ($(".js-check-all-idea:checked").length === $(".js-check-all-idea").length) {
        $(".js-check-all").prop("checked", true);
        showBulkActionsButton();
      }

      if ($(ev.target).prop("checked")) {
        showBulkActionsButton();
        $(ev.target).closest("tr").addClass("selected");
      } else {
        window.hideBulkActionsButton();
        $(ev.target).closest("tr").removeClass("selected");
      }

      if ($(".js-check-all-idea:checked").length === 0) {
        window.hideBulkActionsButton();
      }

      $(".js-bulk-action-form").find(`.js-idea-id-${ideaId}`).prop("checked", checked);
      window.selectedIdeasCountUpdate();
    });

    $(".js-cancel-bulk-action").on("click", () => {
      window.hideBulkActionForms()
      showBulkActionsButton();
      window.showOtherActionsButtons();
    });
  }
});
