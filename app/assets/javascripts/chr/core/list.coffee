# -----------------------------------------------------------------------------
# LIST
# -----------------------------------------------------------------------------
class @List
  _loading: (callback) ->
    @$el.addClass 'list-loading'
    callback()

  _path: ->
    crumbs = [] ; l = this
    while l.parentList
      crumbs.push(l.name) ; l = l.parentList
    @module.name + ( if crumbs.length > 0 then '/' + crumbs.reverse().join('/') else '' )

  _updateItemPosition: (item, position) ->
    position = @configItemsCount + position
    if position == 0
      @$items.prepend(item.$el)
    else
      @$items.append(item.$el.hide())
      $(@$items.children()[position - 1]).after(item.$el.show())

  _addItem: (path, object, position, config) ->
    item = new @itemClass(@module, path, object, config)
    @items[object._id] = item
    @_updateItemPosition(item, position)

  _processConfigItems: ->
    for slug, config of @config.items
      object = { _id: slug, _title: config.title ? slug.titleize() }

      if config.objectStore
        $.extend(object, config.objectStore.get())

      if config.items or config.arrayStore
        @module.addNestedList(slug, config, this)

      @_addItem("#/#{ @path }/#{ slug }", object, 0, config)
      @configItemsCount += 1

  _bindConfigObjectStore: ->

  _bindConfigArrayStore: ->

    # NOTE: starts data fetch
    @config.arrayStore.on 'object_added', (e, data) =>
      @_addItem("#/#{ @path }/view/#{ data.object._id }", data.object, data.position, @config)
      data.callback?(data.object)

    @config.arrayStore.on 'object_changed', (e, data) =>
      item = @items[data.object._id]
      item.render()
      @_updateItemPosition(item, data.position)
      data.callback?(data.object)

    @config.arrayStore.on 'object_removed', (e, data) =>
      @items[data.object_id].destroy()
      delete @items[data.object_id]

    @config.arrayStore.on 'objects_added', (e, data) =>
      @$el.removeClass 'list-loading'

    if @config.arrayStore.pagination
      _listBindScroll(this)

    if @config.arrayStore.searchable
      _listBindSearch(this)

    if @config.arrayStore.reorderable
      _listBindReorder(this)

  constructor: (@module, @name, @config, @parentList) ->
    @configItemsCount = 0
    @path           = @_path()
    @items          = {}
    @title          = @config.title      ? @name.titleize()
    @itemClass      = @config.itemClass  ? Item
    @showWithParent = @config.showListWithParent ? false

    @$el =$ "<div class='list #{ @name }'>"
    @module.$el.append @$el

    if @parentList then @$el.hide() # hide all nested lists

    @$items =$ "<div class='items'>"
    @$el.append @$items

    @$header =$ "<header></header>"

    if @parentList
      # NOTE: show back button for nested list
      @parentListPath = @parentList.path
      @$backBtn =$ "<a href='#/#{ @parentListPath }' class='back silent'></a>"
      @$backBtn.on 'click', (e) => @onBack(e)
      @$header.prepend @$backBtn
    else
      @$backBtn =$ "<a href='#/' class='back'></a>"
      @$header.prepend @$backBtn


    @$header.append "<span class='title'>#{ @title }</span>"

    if not @config.disableNewItems and @config.formSchema
      @$newBtn =$ "<a href='#/#{ @path }/new' class='new silent'></a>"
      @$newBtn.on 'click', (e) => @onNew(e)
      @$header.append @$newBtn

    @$search =$ """<div class='search' style='display: none;'>
                     <a href='#' class='icon'></a>
                     <input type='text' placeholder='Search...' />
                     <a href='#' class='cancel'>Cancel</a>
                   </div>"""
    @$header.append @$search

    @$el.append @$header

    if @config.items       then @_processConfigItems()
    if @config.arrayStore  then @_bindConfigArrayStore()
    if @config.objectStore then @_bindConfigObjectStore()

    @config.onListInit?(@)

  selectItem: (href) ->
    @$items.children("a[href='#{ href }']").addClass 'active'

  unselectItems: ->
    @$items.children().removeClass 'active'

  hide: (animate) ->
    @unselectItems()
    if animate then @$el.fadeOut() else @$el.hide()

  show: (animate=false, callback) ->
    if animate
      @$el.css('z-index', 1)
      @$el.fadeIn $.fx.speeds._default, => @$el.css('z-index', '') ; callback?()
    else
      @$el.show()

  onBack: (e) ->
    @unselectItems()
    @module.destroyView()

    if @showWithParent
      @hide(true)
      @module.unselectActiveListItem()
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



