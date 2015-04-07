# -----------------------------------------------------------------------------
# LIST PAGINATION
# -----------------------------------------------------------------------------

@listPagination =

  # PRIVATE ===============================================

  _bind_pagination: ->
    @lastScrollTop = 0

    @$items.scroll (e) =>
      # trigger next page loading only when scrolling to bottom
      if @lastScrollTop < e.target.scrollTop
        @lastScrollTop = e.target.scrollTop

        if ! @config.arrayStore.dataFetchLock

          if @listItemsHeight < (@listViewHeight + e.target.scrollTop + 100)
            @_show_spinner()
            @config.arrayStore.load
              onSuccess: => @_update_height_params()
              onError:   => chr.showAlert("Can't load next page, server error 500.")

    @_update_height_params()


  _update_height_params: ->
    @listViewHeight  = @$el.height()
    @listItemsHeight = 0
    @$items.children().each (i, el) => @listItemsHeight += $(el).height()




