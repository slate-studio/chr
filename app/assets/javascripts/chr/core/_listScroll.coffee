# -----------------------------------------------------------------------------
# LIST SCROLL
# -----------------------------------------------------------------------------
@_listBindScroll = (listEl) ->
  $container = listEl.$el
  $list      = listEl.$items
  arrayStore = listEl.config.arrayStore

  $list.scroll (e) =>
    if not arrayStore.dataFetchLock
      $listChildren        = $list.children()
      listChildrenCount    = $listChildren.length
      listFirstChildHeight = $listChildren.first().outerHeight()
      listHeight           = listChildrenCount * listFirstChildHeight
      viewHeight           = $container.height()

      if listHeight < (viewHeight + e.target.scrollTop + 100)
        listEl._loading -> arrayStore.load()





