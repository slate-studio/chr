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
        if ! @config.arrayStore.dataFetchLock

          listViewHeight  = @$el.height()
          listItemsHeight = 0
          @$items.children().each -> listItemsHeight += $(this).height()

          if listItemsHeight < (listViewHeight + e.target.scrollTop + 100)

            if ! @config.arrayStore.lastPageLoaded

              @_show_spinner()

              @config.arrayStore.load false,
                onSuccess: => ;
                onError:   => chr.showAlert("Can't load next page, server error 500.")

      @lastScrollTop = e.target.scrollTop




