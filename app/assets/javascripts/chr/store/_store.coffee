# -----------------------------------------------------------------------------
# OBJECT STORE
# -----------------------------------------------------------------------------
class @ObjectStore
  constructor: (@config={}) ->
    @_initializeDatabase()

  _fetchData: ->
    @_data = @config.data

  _initializeDatabase: ->
    @_fetchData()

  get: ->
    @_data

  _updateDataObject: (value, callback) ->
    callback?($.extend(@_data, value))

  update: (id, value, callback) ->
    @_updateDataObject(value, callback)


# -----------------------------------------------------------------------------
# ARRAY STORE
# -----------------------------------------------------------------------------
class @ArrayStore
  _sortData: ->
    # http://stackoverflow.com/questions/9796764/how-do-i-sort-an-array-with-coffeescript
    if @sortBy
      fieldName = @sortBy
      direction = if @sortReverse then 1 else -1

      sortBy = (key, a, b, dir) ->
        if a[key] > b[key] then return -1*dir
        if a[key] < b[key] then return +1*dir
        return 0

      @_data = @_data.sort (a, b) -> sortBy(fieldName, a, b, direction)

  _mapData: ->
    ( @_map[o._id] = o for o in @_data )

  _addDataObject: (object, callback)->
    @_map[object._id] = object
    @_data.push(object)
    @_sortData()
    position = @_getDataObjectPosition(object._id)
    $(this).trigger('object_added', { object: object, position: position, callback: callback })

  _resetData: ->
    for id, o of @_map
      $(this).trigger('object_removed', { object_id: id })
    @_map  = {}
    @_data = []

  _removeDataObject: (id) ->
    position = @_getDataObjectPosition(id)
    if position >= 0
      delete @_data[position]
    delete @_map[id]
    $(this).trigger('object_removed', { object_id: id })

  _updateDataObject: (id, value, callback) ->
    object = $.extend(@get(id), value)
    @_sortData()
    position = @_getDataObjectPosition(id)
    $(this).trigger('object_changed', { object: object, position: position, callback: callback })

  _getDataObjectPosition: (id) ->
    ids = []
    for o in @_data
      if o then ids.push(o._id)
    $.inArray id, ids

  constructor: (@config={}) ->
    @_map  = {}
    @_data = []
    @_initializeDatabase()

  _initializeDatabase: ->

  off: (eventType) ->
    if eventType then $(this).off(eventType) else $(this).off()

  on: (eventType, callback) -> # event types: object_added, object_changed, object_removed
    $(this).on eventType, (e, data) -> callback(e, data)
    # NOTE: this called once when list subscribes to store updates
    if eventType == 'object_added' then @_fetchData()

  _fetchData: ->
    if @config.data
      @_addDataObject(o) for o in @config.data

  get: (id) -> @_map[id]

  update: (id, value, callback) ->
    @_updateDataObject(id, value, callback)

  push: (value, callback) ->
    @_addDataObject($.extend({ _id: Date.now() }, value), callback)

  remove: (id) ->
    @_removeDataObject(id)
