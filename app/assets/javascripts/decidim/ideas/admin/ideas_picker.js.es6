$(() => {
  const $content = $(".picker-content"),
      pickerMore = $content.data("picker-more"),
      pickerPath = $content.data("picker-path"),
      toggleNoIdeas = () => {
        const showNoIdeas = $("#ideas_list li:visible").length === 0
        $("#no_ideas").toggle(showNoIdeas)
      }

  let jqxhr = null

  toggleNoIdeas()

  $(".data_picker-modal-content").on("change keyup", "#ideas_filter", (event) => {
    const filter = event.target.value.toLowerCase()

    if (pickerMore) {
      if (jqxhr !== null) {
        jqxhr.abort()
      }

      $content.html("<div class='loading-spinner'></div>")
      jqxhr = $.get(`${pickerPath}?q=${filter}`, (data) => {
        $content.html(data)
        jqxhr = null
        toggleNoIdeas()
      })
    } else {
      $("#ideas_list li").each((_index, li) => {
        $(li).toggle(li.textContent.toLowerCase().indexOf(filter) > -1)
      })
      toggleNoIdeas()
    }
  })
})
