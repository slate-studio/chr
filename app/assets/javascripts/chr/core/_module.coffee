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


  _updateActiveListItems: ->
    # NOTE: update list data if it's not visible, e.g. for update action we do not
    #       update whole list, this function should be called before active list got shown.
    if not @activeList.isVisible()
      @activeList.updateItems()

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
    newView = new View(this, config, @activeList.path, object, title)
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

    @_updateActiveListItems()
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

  showNestedList: (listName, animate=false) ->
    @selectActiveListItem(location.hash)
    @activeList = @nestedLists[listName]

    @_updateActiveListItems()

    @activeList.show(animate)
    if animate and @view then @view.$el.fadeOut $.fx.speeds._default, => @destroyView()

  hideNestedLists: ->
    @activeList = @rootList
    list.hide() for key, list of @nestedLists

  showViewWhenObjectsAreReady: (objectId, config) ->
    object = config.arrayStore.get(objectId)
    if object then return @showView(object, config)

    $(config.arrayStore).one 'objects_added', (e, data) =>
      object = config.arrayStore.get(objectId)
      if object then return @showView(object, config)

      console.log "object #{objectId} is not in the list"





