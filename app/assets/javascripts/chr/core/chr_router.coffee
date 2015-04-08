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

    # if module changed, hide previous module
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

          if config.objectStore
            return @module.showViewByObjectId('', config, crumb.titleize())

          else
            @module.showList(crumb)




