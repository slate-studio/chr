# -----------------------------------------------------------------------------
# LIST SCROLL
# todo:
#  - trigger onScroll event only when scrolling down
# -----------------------------------------------------------------------------
@_listBindPagination = (listEl) ->
  $container = listEl.$el
  $list      = listEl.$items
  arrayStore = listEl.config.arrayStore

  $list.scroll (e) =>
    if ! arrayStore.dataFetchLock
      $listChildren        = $list.children()
      listChildrenCount    = $listChildren.length
      listFirstChildHeight = $listChildren.first().outerHeight()
      listHeight           = listChildrenCount * listFirstChildHeight
      viewHeight           = $container.height()

      if listHeight < (viewHeight + e.target.scrollTop + 100)
        listEl._show_spinner()
        arrayStore.load()




