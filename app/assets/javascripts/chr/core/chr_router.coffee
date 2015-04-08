# -----------------------------------------------------------------------------
# Author: Alexander Kravets <alex@slatestudio.com>,
#         Slate Studio (http://www.slatestudio.com)
#
# Coding Guide:
#   https://github.com/thoughtbot/guides/tree/master/style/coffeescript
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# CHARACTER ROUTER
# -----------------------------------------------------------------------------

@chrRouter =

  # PRIVATE ===============================================

  _route: (path) -> #/<module>[/<list>][/new]OR[/view/<objectId>]
    crumbs = path.split('/')
    update_list_items = true


    if @module
      path = location.hash

      # do not update items when return to active list from view
      if @module.activeList.path == path
        update_list_items = false

      # do not update items when show view
      view_path = path.replace(@module.activeList.path, '')

      if view_path.startsWith('/new') || view_path.startsWith('/view')
        update_list_items = false


    # if module changed, hide previous module & update list items
    if @module != @modules[crumbs[1]]
      @module?.hide()


    @module = @modules[crumbs[1]] # module name on position 1


    if @module
      @module.show()

      config = @module.config
      crumbs = crumbs.splice(2) # remove #/<module> part

      if crumbs.length > 0
        for crumb in crumbs
          if crumb == 'new'
            return @module.showView(null, config, 'New')

          if crumb == 'view'
            objectId = _last(crumbs)
            return @module.showViewByObjectId(objectId, config)

          config = config.items[crumb]

          if config
            if config.objectStore
              return @module.showViewByObjectId('', config, crumb.titleize())

            else
              @module.showList(crumb)

              if update_list_items # for nested lists
                @module.activeList.updateItems()
      else
        if update_list_items # for root list
          @module.activeList.updateItems()




