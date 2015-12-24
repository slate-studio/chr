# -----------------------------------------------------------------------------
# LIST TABS
# -----------------------------------------------------------------------------
@listTabs =

  # PRIVATE ===================================================================

  _bind_tabs: ->
    @$title.addClass "title-with-tabs"
    @$tabs =$ "<aside class='header-tabs'>"
    @$title.after @$tabs
    @tabLinks = []

    for title, urlParams of @config.listTabs
      @_add_tab(title, urlParams)

    $firstTab = @tabLinks[0]
    @selectTab($firstTab, false)

  _add_tab: (title, urlParams) ->
    $tab =$ "<button>#{title}</button>"
    @$tabs.append $tab
    @tabLinks.push $tab

    $tab.on "click", (e) =>
      $tab =$ e.currentTarget
      @selectTab($tab, true)

  # PUBLIC ====================================================================

  selectTab: ($tab, resetList) ->
    @$tabs.children().removeClass "active"
    $tab.addClass "active"
    tabName = $tab.html()
    params = @config.listTabs[tabName]

    if resetList
      @showSpinner()
      @config.arrayStore.filter(params)
    else
      @config.arrayStore.filterParams = params
