# -----------------------------------------------------------------------------
# LIST SEARCH
# -----------------------------------------------------------------------------
@_listBindSearch = (listEl) ->
  $input     = listEl.$search
  arrayStore = listEl.config.arrayStore

  runSearch = (input) ->
    query = $(input).val()
    listEl._show_spinner()
    arrayStore.search(query)

  showSearch = ->
    listEl.$el.addClass 'list-search'
    $input.find('input').focus()

  cancelSearch = ->
    listEl.$el.removeClass 'list-search'
    $input.find('input').val('')
    listEl._show_spinner()
    arrayStore.reset()

  $input.show()

  $input.on 'keyup', 'input', (e) =>
    if e.keyCode == 27 # esc
      return cancelSearch()

    if e.keyCode == 13 # enter
      return runSearch(e.target)

  $input.on 'click', '.icon', (e)   => e.preventDefault() ; showSearch()
  $input.on 'click', '.cancel', (e) => e.preventDefault() ; cancelSearch()




