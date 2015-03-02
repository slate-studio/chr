# -----------------------------------------------------------------------------
# Character
# -----------------------------------------------------------------------------
class @Chr
  constructor: (@config) ->
    @modules = {}

    @$el       =$ (@config.selector ? 'body')
    @$navBar   =$ "<nav class='sidebar'>"
    @$mainMenu =$ "<div class='menu'>"

    @$navBar.append @$mainMenu
    @$el.append @$navBar

    @modules[name] = new Module(this, name, config) for name, config of @config.modules

    # NAVIGATION
    # using class 'silent' for links when we don't want to trigger onhashchange event
    $(document).on 'click', 'a.silent', (e) -> window._skipHashchange = true

    window.onhashchange = =>
      if not window._skipHashchange then @_navigate(location.hash)
      window._skipHashchange = false

    # if not mobile navigate on first page load or page refresh
    if not _isMobile()
      window._skipHashchange = false
      @_navigate(if location.hash != '' then location.hash else '#/' + Object.keys(@modules)[0])

  addMenuItem: (moduleName, title) ->
    @$mainMenu.append "<a href='#/#{ moduleName }'>#{ title }</a>"

  selectMenuItem: (href) ->
    @$mainMenu.children().removeClass 'active'
    @$mainMenu.children("a[href='#/#{ href }']").addClass 'active'

  unselectMenuItem: ->
    @$mainMenu.children().removeClass 'active'

  # TODO: this piece of navigation code isn't clear, need to refactor to make
  #       it more readable
  _navigate: (path) ->
    # #/<module>[/<list>][/new]OR[/view/<objectId>]
    crumbs = path.split('/')

    @unselectMenuItem()

    # if module changed, hide previous module
    if @module != @modules[crumbs[1]]
      @module?.hide((path == '#/')) # NOTE: animate only for root path

    @module = @modules[crumbs[1]] # module name on position 1

    if @module
      @module.show()

      config = @module.config
      crumbs = crumbs.splice(2) # remove #/<module> part

      if crumbs.length > 0
        for crumb in crumbs
          if crumb == 'new'
            # TODO: reset list data
            return @module.showView(null, config, 'New')

          if crumb == 'view'
            objectId = _last(crumbs)
            return @module.showViewWhenObjectsAreReady(objectId, config)

          config = config.items[crumb]

          if config.objectStore
            # TODO: check if object is loaded and if it's not load it first
            object = $.extend({ _id: crumb }, config.objectStore.get())
            return @module.showView(object, config, crumb.titleize())

          else
            @module.showNestedList(crumb)
      else
        # NOTE: show module root list for the case when same module picked
        @module.destroyView()
        while @module.activeList != @module.rootList
          @module.hideActiveList(false)






