# -----------------------------------------------------------------------------
# Author: Alexander Kravets <alex@slatestudio.com>,
#         Slate Studio (http://www.slatestudio.com)
#
# Coding Guide:
#   https://github.com/thoughtbot/guides/tree/master/style/coffeescript
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# MODULE
#
# configuration options:
#   @config.title                - title used for menu and root list header
#   @config.showNestedListsAside - show module root list on the left and all
#                                  nested lists on the right side for desktop
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
      if ! _isMobile() && firstNestedList
        menuPath += "/#{ firstNestedList.name }"

    @chr.addMenuItem(menuPath, menuTitle)

    @config.onModuleInit?(this)


  # update list data if it's not visible, e.g. for update action we do not
  # update whole list, this method is called before active list is shown.
  _update_active_list_items: ->
    if not @activeList.isVisible()
      @activeList.updateItems()


  # returns path for the current list
  _view_path: ->
    currentList = @visibleNestedListShownWithParent() ? @activeList
    currentList.path


  addNestedList: (listName, config, parentList) ->
    @nestedLists[listName] = new List(this, listName, config, parentList)


  hideActiveList: (animate=false)->
    if animate then @activeList.$el.fadeOut() else @activeList.$el.hide()
    @activeList = @activeList.parentList


  showView: (object, config, title, animate=false) ->
    newView = new View(this, config, @_view_path(), object, title)
    @chr.$el.append(newView.$el)

    newView.show animate, =>
      @destroyView()
      @view = newView


  destroyView: ->
    @view?.destroy()


  show: ->
    @_update_active_list_items()
    @$el.show()
    @activeList.show(false)


  hide: (animate=false) ->
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

      # load an object from store and show view for it
      config.arrayStore.loadObject objectId,
        onSuccess: (object) =>
          console.log object
          @showView(object, config)
        onError: ->
          console.log 'can\'t show view for requested object'


  # returns visible nested list that acts as view
  visibleNestedListShownWithParent: ->
    for key, list of @nestedLists
      if list.isVisible() && list.showWithParent then return list




