# -----------------------------------------------------------------------------
# LIST SEARCH
# -----------------------------------------------------------------------------

@listSearch =
  # PRIVATE ===============================================

  _bind_search: (listEl) ->
    $input     = listEl.$search
    arrayStore = listEl.config.arrayStore

    search = (input) ->
      query = $(input).val()
      listEl._show_spinner()
      arrayStore.search(query)

    show = ->
      listEl.$el.addClass 'list-search'
      $input.find('input').focus()

    cancel = ->
      listEl.$el.removeClass 'list-search'
      $input.find('input').val('')
      listEl._show_spinner()
      arrayStore.reset()

    $input.show()

    $input.on 'keyup', 'input', (e) =>
      if e.keyCode == 27 # esc
        return cancel()

      if e.keyCode == 13 # enter
        return search(e.target)

    $input.on 'click', '.icon',   (e) => e.preventDefault() ; show()
    $input.on 'click', '.cancel', (e) => e.preventDefault() ; cancel()




