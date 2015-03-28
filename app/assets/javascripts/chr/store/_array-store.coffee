# -----------------------------------------------------------------------------
# ARRAY STORE
# javascript object storage implementation that stores/loads objects in memory,
# no backend database support here, supported features are:
#   - new / update / remove
#   - sorting
#   - reordering
#
# configuration options:
#   @config.data         — initial array of objects, default: []
#   @config.sortBy       — objects field name which is used for sorting, does
#                          not sort when parameter is not provided, default: nil
#   @config.sortReverse  — reverse objects sorting (descending order),
#                          default: false
#   @config.reorderable  — list items reordering configuration hash, should
#                          have two fields:
#                            { positionFieldName: '',
#                              sortReverse:       false }
#
# public methods:
#   - on(eventType, callback)
#   - off(eventType)
#   - get(id)
#   - push(serializedFormObject, callbacks)
#   - update(serializedFormObject, callbacks)
#   - remove(id)
#   - reset(callback)
#
# todo:
#   - support for lists, files, nested objects
# -----------------------------------------------------------------------------
class @ArrayStore
  constructor: (@config={}) ->
    @_map  = {} # objecs map for fast access by id
    @_data = [] # stores objects in order

    @sortBy      = @config.sortBy      ? false
    @sortReverse = @config.sortReverse ? false
    @reorderable = @config.reorderable ? false

    @_initialize_reorderable()
    @_initialize_database()


  # when store is reorderable update sorting configuration
  _initialize_reorderable: ->
    if @reorderable
      if @reorderable.positionFieldName
        @sortBy      = @reorderable.positionFieldName
        @sortReverse = @reorderable.sortReverse ? false
      else
        console.log 'Wrong reordering configuration, missing positionFieldName parameter.'
        @reorderable = false


  # this method should be overriden for database initialization
  # and config processing when implementing custom store
  _initialize_database: ->
    ;


  # add objects from @config.data,
  # trigger 'objects_added' event
  _fetch_data: ->
    if @config.data
      @_add_data_object(o) for o in @config.data

    $(this).trigger('objects_added')


  # sort object in _data array based on sortBy and sortReverse parameters
  # implementatin details:
  #   http://stackoverflow.com/questions/9796764/how-do-i-sort-an-array-with-coffeescript
  _sort_data: ->
    if @sortBy
      fieldName = @sortBy
      direction = if @sortReverse then 1 else -1

      sortByMethod = (key, a, b, dir) ->
        if a[key] > b[key] then return -1*dir
        if a[key] < b[key] then return +1*dir
        return 0

      @_data = @_data.sort (a, b) -> sortByMethod(fieldName, a, b, direction)


  # gets objects position in _data array by objects id
  _get_data_object_position: (id) ->
    ids = []
    for o in @_data
      if o then ids.push(o._id)
    $.inArray id, ids


  # if objects id stored in id field, map it to _id as this is one
  # which is used internally, this method might be more sophisticated
  _normalize_object_id: (object) ->
    if object.id
      object._id = object.id
      delete object.id
    return object


  # normalize objects id, add object to _data and _map, sort objects,
  # trigger 'object_added' event
  _add_data_object: (object) ->
    object = @_normalize_object_id(object)

    # if object with same id already in the store, update it's parameters,
    # otherwise add new object (this is used while pagination sync)
    if ! @_map[object._id]
      @_map[object._id] = object
      @_data.push(object)
      @_sort_data()

      position = @_get_data_object_position(object._id)

      $(this).trigger('object_added', { object: object, position: position })
    else
      @_update_data_object(object.id, object)


  # get object by id, update it's attributes, sort objects,
  # trigger 'object_changed' event
  _update_data_object: (id, value) ->
    object = $.extend(@get(id), value)

    @_sort_data()

    position = @_get_data_object_position(id)

    $(this).trigger('object_changed', { object: object, position: position })


  # delete object by id from _data and _map,
  # trigger 'object_removed' event
  _remove_data_object: (id) ->
    position = @_get_data_object_position(id)
    if position >= 0
      @_data.splice(position, 1)

    delete @_map[id]

    $(this).trigger('object_removed', { object_id: id })


  # remove all objects from _data and _map,
  # trigger 'object_removed' event for each
  _reset_data: ->
    for id, o of @_map
      $(this).trigger('object_removed', { object_id: id })

    @_map  = {}
    @_data = []


  # get regular javascript object from serialized form object,
  # which uses special format for object names for support of:
  # - files
  # - lists
  # - nested objects
  _parse_form_object: (serializedFormObject) ->
    # this is very basic and have to be expanded to support all form inputs:
    #  - lists, files, nested objects
    object = {}
    for key, value of serializedFormObject
      fieldName = key.replace('[', '').replace(']', '')
      object[fieldName] = value
    return object


  # unsubscribe from store event, simple jQuery wrapper
  off: (eventType) ->
    if eventType then $(this).off(eventType) else $(this).off()


  # subsribe to store event, available event types:
  #  - object_added
  #  - object_changed
  #  - object_removed
  #  - objects_added
  on: (eventType, callback) ->
    $(this).on eventType, (e, data) -> callback(e, data)


  # get object by id
  get: (id) ->
    @_map[id]


  # add new object
  push: (serializedFormObject, callbacks={}) ->
    object = @_parse_form_object(serializedFormObject)

    # generate id for new object
    if ! object._id then object._id = Date.now()

    @_add_data_object(object)
    callbacks.onSuccess?()


  # update objects attributes
  update: (id, serializedFormObject, callbacks={}) ->
    object = @_parse_form_object(serializedFormObject)
    @_update_data_object(id, object)
    callbacks.onSuccess?()


  # delete object
  remove: (id, callbacks={}) ->
    @_remove_data_object(id)
    callbacks.onSuccess?()


  # do nothing for in memory data store
  reset: ->
    $(this).trigger('objects_added')




