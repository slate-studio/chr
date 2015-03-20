# -----------------------------------------------------------------------------
# MODULE
# -----------------------------------------------------------------------------
class @Module
  constructor: (@chr, @name, @config) ->
    @nestedLists = {}

    @$el = $("<section class='module #{ @name }' style='display: none;'>")
    @chr.$el.append @$el

    menuTitle  = @config.menuTitle ? @config.title
    menuTitle ?= @name.titleize()
    @chr.addMenuItem(@name, menuTitle)

    @activeList = @rootList = new List(this, @name, @config)

    @config.onModuleInit?(this)


  # update list data if it's not visible, e.g. for update action we do not
  # update whole list, this method is called before active list is shown.
  _update_active_list_items: ->
    if not @activeList.isVisible()
      @activeList.updateItems()


  # returns visible nested list that acts as view
  _visible_nested_list_shown_with_parent: ->
    for key, list of @nestedLists
      if list.isVisible() && list.showWithParent then return list


  # returns path for the current list
  _view_path: ->
    currentList = @_visible_nested_list_shown_with_parent() ? @activeList
    currentList.path


  addNestedList: (listName, config, parentList) ->
    @nestedLists[listName] = new List(this, listName, config, parentList)


  selectActiveListItem: (href) ->
    @unselectActiveListItem()
    @activeList.selectItem(href)


  unselectActiveListItem: ->
    @activeList?.unselectItems()


  hideActiveList: (animate=false)->
    if animate then @activeList.$el.fadeOut() else @activeList.$el.hide()
    @activeList = @activeList.parentList
    @unselectActiveListItem()


  showView: (object, config, title, animate=false) ->
    newView = new View(this, config, @_view_path(), object, title)
    @chr.$el.append(newView.$el)

    @selectActiveListItem(location.hash)

    newView.show animate, =>
      @destroyView()
      @view = newView


  destroyView: ->
    @view?.destroy()


  show: ->
    @chr.selectMenuItem(@name)
    @unselectActiveListItem()

    @_update_active_list_items()
    @$el.show()
    @activeList.show(false)


  hide: (animate=false) ->
    @unselectActiveListItem()
    @hideNestedLists()

    if animate
      # TODO: move animation to the view class
      if @view then @view.$el.fadeOut $.fx.speeds._default, => @destroyView()
      @$el.fadeOut()
    else
      @destroyView()
      @$el.hide()


  # shows one of nested lists, with or without animation
  showNestedList: (listName, animate=false) ->
    listToShow = @nestedLists[listName]

    @selectActiveListItem(location.hash)

    if listToShow.showWithParent
      # list works as view, it never becomes active
      listToShow.updateItems()
      listToShow.show animate, => @hideNestedLists(exceptList=listName)

    else
      @activeList = listToShow
      @_update_active_list_items()
      @activeList.show(animate)

    # hide view
    if animate and @view then @view.$el.fadeOut $.fx.speeds._default, => @destroyView()


  hideNestedLists: (exceptList)->
    @activeList = @rootList
    list.hide() for key, list of @nestedLists when key isnt exceptList


  showViewWhenObjectsAreReady: (objectId, config) ->
    object = config.arrayStore.get(objectId)
    if object then return @showView(object, config)

    $(config.arrayStore).one 'objects_added', (e, data) =>
      object = config.arrayStore.get(objectId)
      if object then return @showView(object, config)

      console.log "object #{objectId} is not in the list"





