# -----------------------------------------------------------------------------
# LIST PAGINATION
# -----------------------------------------------------------------------------

@listPagination =
  # PRIVATE ===============================================

  _bind_pagination: ->
    if chr.isMobile()
      chr._bind_mobile_scroll()

    else
      @_bind_desktop_scroll()


  _bind_desktop_scroll: ->
    @lastScrollTop = 0
    $viewport      = @$el

    @$items.scroll (e) =>
      scroll_top = @$items.scrollTop()

      # trigger next page loading only when scrolling to bottom
      if @lastScrollTop < scroll_top
        chr._load_next_page($viewport, this, scroll_top)

      @lastScrollTop = scroll_top


chr._bind_mobile_scroll = ->
  if ! @_mobile_scroll_binded
    @lastScrollTop = 0
    $viewport      = $(window)

    $viewport.scroll (e) =>
      scroll_top = $viewport.scrollTop()

      # trigger next page loading only when scrolling to bottom
      if @lastScrollTop < scroll_top

        if ! @module then return

        if @module.view then return

        chr._load_next_page($viewport, @module.activeList, scroll_top)

      @lastScrollTop = scroll_top

    @_mobile_scroll_binded = true


chr._load_next_page = ($viewport, list, scroll_top) ->
  $items = list.$items
  store  = list.config.arrayStore

  if store.dataFetchLock then return

  if store.lastPageLoaded then return

  # check if scroll is near bottom of the $viewport
  viewport_height   = $viewport.height()
  list_items_height = 0
  $items.children().each -> list_items_height += $(this).height()

  if list_items_height - scroll_top - 100 > viewport_height
    return

  list.showSpinner()
  store.load false,
    onSuccess: => ;
    onError:   => chr.showAlert("Can't load next page, server error 500.")




