# -----------------------------------------------------------------------------
# Author: Alexander Kravets <alex@slatestudio.com>,
#         Slate Studio (http://www.slatestudio.com)
#
# Coding Guide:
#   https://github.com/thoughtbot/guides/tree/master/style/coffeescript
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# LIST
#
# configuration options:
#   itemClass          - item class to be used instead of default one
#   itemTitleField     - object attributes name for list item title
#   itemSubtitleField  - object attributes name for list item subtitle
#   disableNewItems    - do not show new item button in list header
#   disableUpdateItems - do not update list items
#   onListInit         - callback on list is initialized
#   onListShow         - callback on list is shown
#   objects            - objects array to be added to the store on start
#
# public methods:
#   hide()        - hide list
#   show()        - show list
#   updateItems() - update list items (sync through store with backend)
#   isVisible()   - check if list is visible
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
      @$backBtn.on 'click', (e) => @_on_back(e)
    else
      @$backBtn =$ "<a href='#/' class='back'></a>"
    @$header.prepend @$backBtn

    # spinner & title
    @$header.append "<div class='spinner'></div>"
    @$header.append "<span class='title'>#{ @title }</span>"

    # new item button
    if not @config.disableNewItems and @config.formSchema
      @$newBtn =$ "<a href='#/#{ @path }/new' class='new silent'></a>"
      @$newBtn.on 'click', (e) => @_on_new(e)
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


  _process_config_items: ->
    for slug, config of @config.items
      object = { _id: slug, _title: config.title ? slug.titleize() }

      #if config.objectStore
      #  $.extend(object, config.objectStore.get())

      if config.items or config.arrayStore
        @module.addNestedList(slug, config, this)

      @_add_item("#/#{ @path }/#{ slug }", object, 0, config)
      @configItemsCount += 1


  _bind_config_object_store: ->


  _bind_config_array_store: ->
    # item added
    @config.arrayStore.on 'object_added', (e, data) =>
      @_add_item("#/#{ @path }/view/#{ data.object._id }", data.object, data.position, @config)

    if @config.objects
      @config.arrayStore.addObjects(@config.objects)

    # item updated
    @config.arrayStore.on 'object_changed', (e, data) =>
      item = @items[data.object._id]
      if item then item.render() ; @_update_item_position(item, data.position)

    # item removed
    @config.arrayStore.on 'object_removed', (e, data) =>
      item = @items[data.object_id]
      if item then item.destroy() ; delete @items[data.object_id]

    # items loaded
    @config.arrayStore.on 'objects_added', (e, data) =>
      @_hide_spinner()
      @_set_active_item()

    if @config.arrayStore.pagination
      _listBindPagination(this)

    if @config.arrayStore.searchable
      _listBindSearch(this)

    if @config.arrayStore.reorderable
      _listBindReorder(this)


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
    @$el.addClass 'show-spinner'


  _hide_spinner: ->
    @$el.removeClass 'show-spinner'


  _on_back: (e) ->
    @module.chr.unsetActiveListItems()
    @module.destroyView()

    if @showWithParent
      @hide(true)
    else
      @module.hideActiveList(true)


  _on_new: (e) ->
    window._skipHashchange = true
    location.hash = $(e.currentTarget).attr('href')
    @module.showView(null, @config, 'New', true)


  hide: (animate) ->
    if animate then @$el.fadeOut() else @$el.hide()


  show: (animate=false, callback) ->
    onShow = =>
      @$items.scrollTop(0)
      @config.onListShow?(@)
      callback?()

    if animate
      # z-index workaround to remove blink effect
      @$el.css({ 'z-index': 1, 'box-shadow': 'none' })
      @$el.fadeIn $.fx.speeds._default, => @$el.css({ 'z-index': '', 'box-shadow': '' }) ; onShow()
    else
      @$el.show() ; onShow()


  updateItems: ->
    if not @config.disableUpdateItems
      if @config.arrayStore
        @_show_spinner()
        @config.arrayStore.reset()


  isVisible: ->
    @$el.is(':visible')




