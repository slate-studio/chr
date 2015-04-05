# -----------------------------------------------------------------------------
# Author: Alexander Kravets <alex@slatestudio.com>,
#         Slate Studio (http://www.slatestudio.com)
#
# Coding Guide:
#   https://github.com/thoughtbot/guides/tree/master/style/coffeescript
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# MODULE
# -----------------------------------------------------------------------------
# Config options:
#   title                - title used for menu and root list header
#   showNestedListsAside - show module root list on the left and all nested
#                          lists on the right side for desktop
#
# Public methods:
#   addNestedList (listName, config, parentList)
#   showNestedList (listName)
#   hideNestedLists (exceptList)
#   visibleNestedListShownWithParent ()
#   showRootList ()
#   hideActiveList ()
#   showView (object, config, title)
#   showViewByObjectId (objectId, config, title)
#   destroyView ()
#   show ()
#   hide ()
#
# -----------------------------------------------------------------------------
class @Module
  constructor: (@chr, @name, @config) ->
    @nestedLists = {}

    @$el = $("<section class='module #{ @name }' style='display: none;'>")
    @chr.$el.append @$el

    # root list
    @activeList = @rootList = new List(this, @name, @config)

    # menu item + layout
    menuTitle  = @config.menuTitle ? @config.title
    menuTitle ?= @name.titleize()
    menuPath   = @name

    # do not hide root list layout, nested lists are shown on aside
    if @config.showNestedListsAside
      @$el.addClass 'first-list-aside'
      # jump to first nested list on menu click
      firstNestedList = _firstNonEmptyValue(@nestedLists)
      if ! @chr.isMobile() && firstNestedList
        menuPath += "/#{ firstNestedList.name }"

    @chr.addMenuItem(menuPath, menuTitle)

    @config.onModuleInit?(this)


  # PRIVATE ===============================================

  # update list data if it's not visible, e.g. for update action we do not
  # update whole list, this method is called before active list is shown.
  _update_active_list_items: ->
    if not @activeList.isVisible()
      @activeList.updateItems()


  # returns path for the current list
  _view_path: ->
    currentList = @visibleNestedListShownWithParent() ? @activeList
    currentList.path


  # PUBLIC ================================================

  addNestedList: (listName, config, parentList) ->
    @nestedLists[listName] = new List(this, listName, config, parentList)


  # shows one of nested lists
  showNestedList: (listName) ->
    listToShow = @nestedLists[listName]

    if listToShow.showWithParent
      # list works as view, never becomes active
      listToShow.updateItems()
      listToShow.show => @hideNestedLists(exceptList=listName)

    else
      @activeList = listToShow
      @_update_active_list_items()
      @activeList.show()

    @destroyView()


  hideNestedLists: (exceptList) ->
    @activeList = @rootList
    list.hide() for key, list of @nestedLists when key isnt exceptList


  visibleNestedListShownWithParent: ->
    for key, list of @nestedLists
      if list.isVisible() && list.showWithParent then return list


  showRootList: ->
    @destroyView()
    while @activeList != @rootList
      @hideActiveList()


  hideActiveList: ->
    @activeList.$el.hide()
    @activeList = @activeList.parentList


  showView: (object, config, title) ->
    newView = new View(this, config, @_view_path(), object, title)
    @chr.$el.append(newView.$el)

    newView.show =>
      @destroyView()
      @view = newView


  showViewByObjectId: (objectId, config, title) ->
    onSuccess = (object) => @showView(object, config, title)
    onError   = -> chr.showError("can\'t show view for requested object")

    if objectId == ''
      config.objectStore.loadObject({ onSuccess: onSuccess, onError: onError })
    else
      config.arrayStore.loadObject(objectId, { onSuccess: onSuccess, onError: onError })


  destroyView: ->
    @view?.destroy()


  show: ->
    @_update_active_list_items()
    @$el.show()
    @activeList.show()


  hide: ->
    @hideNestedLists()
    @destroyView()
    @$el.hide()




