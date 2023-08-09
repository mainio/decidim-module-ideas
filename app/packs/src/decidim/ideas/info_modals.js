((exports) => {
  class InfoModal {
    constructor() {
      this.modal = $("#ideas_info-modal");
      if (this.modal.length < 1) {
        this.modal = this._createModalContainer();
        this.modal.appendTo($("body"));
        this.modal.foundation();
      }
    }

    show(url) {
      $.ajax({url: url, dataType: "json"}).done((resp) => {
        let modalContent = $(".ideas_info-modal-content", this.modal);
        modalContent.html(this._generateContent(resp));
        this.modal.foundation("open");
      });
    }

    _generateContent(data) {
      const $content = $("<div></div>");

      if (data.intro) {
        $content.append(`<p>${data.intro}</p>`);
      }
      if (data.text) {
        $content.append(data.text);
      }

      return $content;
    }

    _createModalContainer() {
      return $(`
        <div class="small reveal" id="ideas_info-modal" aria-hidden="true" aria-live="assertive" role="dialog" data-reveal data-multiple-opened="true">
          <div class="ideas_info-modal-content"></div>
          <button class="close-button" data-close type="button" data-reveal-id="ideas_info-modal"><span aria-hidden="true">&times;</span></button>
        </div>
      `);
    }
  }

  const bindInfoModalLinks = () => {
    const modal = new InfoModal();

    exports.$(".info-modal-link").
      off("click.decidim-ideas-info-modal").
      on("click.decidim-ideas-info-modal", (ev) => {
        ev.preventDefault();

        const $link = $(ev.target);
        modal.show($link.attr("href"));
      })
    ;
  }

  exports.$(() => {
    bindInfoModalLinks();
  });

})(window);
