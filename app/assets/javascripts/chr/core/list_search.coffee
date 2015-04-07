# -----------------------------------------------------------------------------
# LIST SEARCH
# -----------------------------------------------------------------------------

@listSearch =

  # PRIVATE ===============================================

  _bind_search: ->
    @$search       =$ "<div class='search'></div>"
    @$searchIcon   =$ "<a href='#' class='icon'></a>"
    @$searchInput  =$ "<input type='text' placeholder='Search...' />"
    @$searchCancel =$ "<a href='#' class='cancel'>Cancel</a>"

    @$header.append(@$search)
    @$search.append(@$searchIcon)
    @$search.append(@$searchInput)
    @$search.append(@$searchCancel)

    @$searchInput.on 'keyup', (e) =>
      if e.keyCode == 27 # esc
        return @_on_search_cancel()

      if e.keyCode == 13 # enter
        return @_on_search()

    @$searchIcon.on   'click', (e) => e.preventDefault() ; @_on_search_show()
    @$searchCancel.on 'click', (e) => e.preventDefault() ; @_on_search_cancel()


  # EVENTS ================================================

  _on_search: ->
    query = @$searchInput.val()
    @_show_spinner()
    @config.arrayStore.search(query)


  _on_search_show: ->
    @$el.addClass('list-search')
    @$searchInput.focus()
    @$search.show()


  _on_search_cancel: ->
    @$el.removeClass('list-search')
    @$searchInput.val('')
    @_show_spinner()
    @config.arrayStore.reset()




