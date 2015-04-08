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
#   menuTitle            - title used for the menu link
#   showNestedListsAside - show module root list on the left and all nested
#                          lists on the right side for desktop
#
# Public methods:
#   addNestedList (listName, config, parentList)
#   showList()
#   showView (object, config, title)
#   showViewByObjectId (objectId, config, title)
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
    @rootList = new List(this, "#/#{ @name }", @name, @config)

    # menu item + layout
    @menuTitle  = @config.menuTitle ? @config.title
    @menuTitle ?= @name.titleize()

    @config.onModuleInit?(this)


  # PRIVATE ===============================================

  _destroy_view: ->
    @view?.destroy()


  # PUBLIC ================================================


  addNestedList: (name, config, parentList) ->
    path = [ parentList.path, name ].join('/')
    @nestedLists[name] = new List(this, path, name, config, parentList)


  showList: (name) ->
    @_destroy_view()
    if ! name
      list.hide() for key, list of @nestedLists
      @activeList = @rootList
    else
      @activeList = @nestedLists[name]

    @activeList.show()


  showView: (object, config, title) ->
    newView = new View(this, config, @activeList.path, object, title)
    @chr.$el.append(newView.$el)

    newView.show =>
      @_destroy_view()
      @view = newView


  showViewByObjectId: (objectId, config, title) ->
    onSuccess = (object) => @showView(object, config, title)
    onError   = -> chr.showError("can\'t show view for requested object")

    if objectId == ''
      config.objectStore.loadObject({ onSuccess: onSuccess, onError: onError })
    else
      config.arrayStore.loadObject(objectId, { onSuccess: onSuccess, onError: onError })


  show: ->
    @$el.show()
    @showList()


  hide: ->
    @_destroy_view()
    @$el.hide()




