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
      @$backBtn.on 'click', (e) => @onBack(e)
    else
      @$backBtn =$ "<a href='#/' class='back'></a>"
    @$header.prepend @$backBtn

    # spinner & title
    @$header.append "<div class='spinner'></div>"
    @$header.append "<span class='title'>#{ @title }</span>"

    # new item button
    if not @config.disableNewItems and @config.formSchema
      @$newBtn =$ "<a href='#/#{ @path }/new' class='new silent'></a>"
      @$newBtn.on 'click', (e) => @onNew(e)
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

    @_update_active_item_on_hashchange()

    @config.onListInit?(@)


  _update_active_item_on_hashchange: ->
    $(chr).on 'hashchange', =>
      hash = window.location.hash
      @$items.children().removeClass('active')
      if hash.startsWith "#/#{ @module.name }"
        for a in @$items.children()
          if hash.startsWith($(a).attr('href'))
            return $(a).addClass('active')


  _path: ->
    crumbs = [] ; l = this
    while l.parentList
      crumbs.push(l.name) ; l = l.parentList
    @module.name + ( if crumbs.length > 0 then '/' + crumbs.reverse().join('/') else '' )


  _process_config_items: ->
    for slug, config of @config.items
      object = { _id: slug, _title: config.title ? slug.titleize() }

      if config.objectStore
        $.extend(object, config.objectStore.get())

      if config.items or config.arrayStore
        @module.addNestedList(slug, config, this)

      @_add_item("#/#{ @path }/#{ slug }", object, 0, config)
      @configItemsCount += 1


  _bind_config_object_store: ->


  _bind_config_array_store: ->
    # callbacks here should be refactored into list events

    # item added
    @config.arrayStore.on 'object_added', (e, data) =>
      @_add_item("#/#{ @path }/view/#{ data.object._id }", data.object, data.position, @config)

      data.callback?(data.object)
      $(this).trigger 'item_added'
      # ^^^ this one

    # item updated
    @config.arrayStore.on 'object_changed', (e, data) =>
      item = @items[data.object._id]
      item.render()
      @_update_item_position(item, data.position)

      data.callback?(data.object)
      $(this).trigger 'item_changed'
      # ^^^ this one

    # item removed
    @config.arrayStore.on 'object_removed', (e, data) =>
      @items[data.object_id]?.destroy()
      delete @items[data.object_id]

      $(this).trigger 'item_removed'

    # items loaded
    @config.arrayStore.on 'objects_added', (e, data) =>
      @$el.removeClass 'list-loading'

    if @config.arrayStore.pagination
      _listBindScroll(this)

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


  _loading: (callback) ->
    @$el.addClass 'list-loading'
    callback?()


  hide: (animate) ->
    if animate then @$el.fadeOut() else @$el.hide()


  show: (animate=false, callback) ->
    if animate
      @$el.css('z-index', 1)
      @$el.fadeIn $.fx.speeds._default, => @$el.css('z-index', '') ; callback?()
    else
      @$el.show()


  onBack: (e) ->
    @module.destroyView()

    if @showWithParent
      @hide(true)
    else
      @module.hideActiveList(true)


  onNew: (e) ->
    window._skipHashchange = true
    location.hash = $(e.currentTarget).attr('href')
    @module.showView(null, @config, 'New', true)


  updateItems: (callback) ->
    if not @config.disableReset
      if @config.arrayStore
        @_loading => @config.arrayStore.reset(callback)


  isVisible: ->
    @$el.is(':visible')




