# -----------------------------------------------------------------------------
# LIST SEARCH
# -----------------------------------------------------------------------------
@_listBindSearch = (listEl) ->
  $input     = listEl.$search
  arrayStore = listEl.config.arrayStore

  $input.show()

  $input.on 'keydown', 'input', (e) =>
    if e.keyCode == 13
      query = $(e.target).val()
      listEl._show_spinner()
      arrayStore.search(query)

  $input.on 'click', '.icon', (e) =>
    e.preventDefault()
    listEl.$el.addClass 'list-search'
    $input.find('input').focus()

  $input.on 'click', '.cancel', (e) =>
    e.preventDefault()
    listEl.$el.removeClass 'list-search'
    $input.find('input').val('')
    listEl._show_spinner()
    arrayStore.reset()




