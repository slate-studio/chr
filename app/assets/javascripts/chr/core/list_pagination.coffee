# -----------------------------------------------------------------------------
# LIST PAGINATION
# todo:
#  - trigger onScroll event only when scrolling down
# -----------------------------------------------------------------------------

@listPagination =
  # PRIVATE ===============================================

  _bind_pagination: ->
    arrayStore = @config.arrayStore
    @$items.scroll (e) =>
      if ! arrayStore.dataFetchLock
        # TODO: update this logic as it's not reliable when items has different height
        $listChildren        = @$items.children()
        listChildrenCount    = $listChildren.length
        listFirstChildHeight = $listChildren.first().outerHeight()
        listHeight           = listChildrenCount * listFirstChildHeight
        viewHeight           = @$el.height()

        if listHeight < (viewHeight + e.target.scrollTop + 100)
          @_show_spinner()
          arrayStore.load()




