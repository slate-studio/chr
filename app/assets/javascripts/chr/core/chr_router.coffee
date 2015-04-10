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

  # format: #/<module>[/<list>]+[/new]OR[/view/<objectId>]
  _parse_path: ->
    params =
      path:               location.hash
      module:             null
      moduleMissing:      false
      moduleHasChanged:   false
      nestedListNames:    []
      lastNestedListName: null
      showNew:            false
      showView:           false
      objectId:           null
      showNestedView:     false

    crumbs                  = params.path.split('/')
    module                  = @modules[crumbs[1]]
    params.module           = module
    params.moduleMissing    = if module then false else true
    params.moduleHasChanged = ( @module != module )

    crumbs = crumbs.splice(2)
    for crumb in crumbs
      if crumb == 'new'
        return $.extend(params, { showNew: true })

      if crumb == 'view'
        return $.extend(params, { showView: true, objectId: _last(crumbs) })

      params.lastNestedListName = crumb
      params.nestedListNames.push(crumb)

    # check if last list name is a name for nested view
    if params.lastNestedListName
      lastList = module.nestedLists[params.lastNestedListName]
      if ! lastList
        nestedViewName            = params.nestedListNames.pop()
        params.lastNestedListName = _last(params.nestedListNames)

        parentList  = module.nestedLists[params.lastNestedListName]
        parentList ?= module.rootList

        params.showNestedView = true
        params.showView       = true
        params.objectId       = ''
        params.config         = parentList.config.items[nestedViewName]

    return params


  _route: ->
    params = @_parse_path()

    if params.moduleMissing
      return

    if params.moduleHasChanged
      @module?.hide()
      @module = params.module

      # show module, root list becomes active
      @module.show()

      # show nested lists
      for listName in params.nestedListNames

        list = @module.nestedLists[listName]

        if list
          # if nested list shown with parent, update parent
          if list.showWithParent
            @module.activeList.updateItems()
          @module.showList(listName)

      # update active list (root list or last nested shown)
      @module.activeList.updateItems()

    else
      @module.destroyView()

      for name, list of @module.nestedLists
        # hide all lists not in the path
        if params.path.indexOf(list.path) != 0
          list.hide()

      update_active_list_items = true

      # show view
      if params.showView || params.showNew
        update_active_list_items = false

      # close view
      if @module.activeList.path == params.path
        update_active_list_items = false

      # back to parent
      if @module.activeList.path.indexOf(params.path) == 0
        update_active_list_items = false

      @module.showList(params.lastNestedListName)

      if update_active_list_items
        @module.activeList.updateItems()


    params.config ?= @module.activeList.config

    # show new
    if params.showNew
      console.log 'show view'
      @module.showView(null, params.config, 'New')

    # show view
    else if params.showView
      console.log 'show view'
      @module.showViewByObjectId(params.objectId, params.config)




