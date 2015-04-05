# -----------------------------------------------------------------------------
# Author: Alexander Kravets <alex@slatestudio.com>,
#         Slate Studio (http://www.slatestudio.com)
#
# Coding Guide:
#   https://github.com/thoughtbot/guides/tree/master/style/coffeescript
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# LIST
# -----------------------------------------------------------------------------
#
# Configuration options:
#   itemClass          - item class to be used instead of default one
#   itemTitleField     - object attributes name for list item title
#   itemSubtitleField  - object attributes name for list item subtitle
#   disableNewItems    - do not show new item button in list header
#   disableUpdateItems - do not update list items
#   onListInit         - callback on list is initialized
#   onListShow         - callback on list is shown
#   objects            - objects array to be added to the store on start
#
# Public methods:
#   hide()        - hide list
#   show()        - show list
#   updateItems() - update list items (sync through store with backend)
#   isVisible()   - check if list is visible
#
# Dependencies:
#= require ./list_config
#= require ./list_pagination
#= require ./list_reorder
#= require ./list_search
#
# -----------------------------------------------------------------------------

class @List
  constructor: (@module, @name, @config, @parentList) ->
    @configItemsCount = 0
    @path           = @_path()
    @items          = {}
    @title          = @config.title      ? @name.titleize()
    @itemClass      = @config.itemClass  ? Item

    @showWithParent = false
    if @parentList
      @showWithParent = @parentList.config.showNestedListsAside || false

    @config.showListWithParent ? false

    @$el =$ "<div class='list #{ @name }'>"
    @module.$el.append @$el

    # hide all nested lists
    if @parentList then @$el.hide()

    # items
    @$items =$ "<div class='items'>"
    @$el.append @$items

    # header
    @$header =$ "<header></header>"
    @$el.append @$header

    # back button
    if @parentList
      @$backBtn =$ "<a href='#/#{ @parentList.path }' class='back silent'></a>"
      @$backBtn.on 'click', (e) => @_back(e)
    else
      @$backBtn =$ "<a href='#/' class='back'></a>"
    @$header.prepend @$backBtn

    # spinner & title
    @$header.append "<div class='spinner'></div>"
    @$header.append "<span class='title'>#{ @title }</span>"

    # new item button
    if not @config.disableNewItems and @config.formSchema
      @$newBtn =$ "<a href='#/#{ @path }/new' class='new silent'></a>"
      @$newBtn.on 'click', (e) => @_new(e)
      @$header.append @$newBtn

    # search
    @$search =$ """<div class='search' style='display: none;'>
                     <a href='#' class='icon'></a>
                     <input type='text' placeholder='Search...' />
                     <a href='#' class='cancel'>Cancel</a>
                   </div>"""
    @$header.append @$search

    if @config.items       then @_process_config_items()
    if @config.arrayStore  then @_bind_config_array_store()
    if @config.objectStore then @_bind_config_object_store()

    @_bind_hashchange()

    @config.onListInit?(@)


  # PRIVATE ===============================================

  _bind_hashchange: ->
    $(chr).on 'hashchange', => @_set_active_item()


  _set_active_item: ->
    hash = window.location.hash
    if hash.startsWith "#/#{ @module.name }"
      for a in @$items.children()
        itemPath = $(a).attr('href')
        if hash.startsWith(itemPath)
          return $(a).addClass('active')


  _path: ->
    crumbs = [] ; l = this
    while l.parentList
      crumbs.push(l.name) ; l = l.parentList
    @module.name + ( if crumbs.length > 0 then '/' + crumbs.reverse().join('/') else '' )


  _add_item: (path, object, position, config) ->
    item = new @itemClass(@module, path, object, config)
    @items[object._id] = item
    @_update_item_position(item, position)


  _update_item_position: (item, position) ->
    position = @configItemsCount + position
    if position == 0
      @$items.prepend(item.$el)
    else
      @$items.append(item.$el.hide())
      $(@$items.children()[position - 1]).after(item.$el.show())


  _show_spinner: ->
    @$el.addClass('show-spinner')


  _hide_spinner: ->
    @$el.removeClass('show-spinner')


  # EVENTS ================================================

  _back: (e) ->
    @module.chr.unsetActiveListItems()
    @module.destroyView()

    if @showWithParent
      @hide()
    else
      @module.hideActiveList()


  _new: (e) ->
    chr.updateHash($(e.currentTarget).attr('href'), true)
    @module.showView(null, @config, 'New')


  # PUBLIC ================================================

  hide: ->
    @$el.hide()


  show: (callback) ->
    @$el.show 0, =>
      @$items.scrollTop(0)
      @config.onListShow?(@)
      callback?()


  updateItems: ->
    if not @config.disableUpdateItems
      if @config.arrayStore
        @_show_spinner()
        @config.arrayStore.reset()


  isVisible: ->
    @$el.is(':visible')


include(List, listConfig)
include(List, listPagination)
include(List, listReorder)
include(List, listSearch)




