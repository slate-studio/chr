# -----------------------------------------------------------------------------
# RAILS OBJECT STORE IMPLEMENTATION
# -----------------------------------------------------------------------------
class @RailsObjectStore extends ObjectStore
  # _initializeDatabase: ->
  #   @database = new Firebase("https://#{ @config.dbName }.firebaseio.com/")
  #   @dataRef  = @database.child(@config.path)
  #   @_fetchData()

  # _fetchData: ->
  #   @dataRef.once 'value', (dataSnapshot) =>
  #     @_data = dataSnapshot.val() ? {}

  # update: (id, value, callback) ->
  #   @dataRef.set value, => @_updateDataObject(value, callback)


# -----------------------------------------------------------------------------
# RAILS ARRAY/COLLECTION STORE IMPLEMENTATION
# -----------------------------------------------------------------------------
class @RailsArrayStore extends ArrayStore
  _initializeDatabase: ->
    @resetData     = false
    @searchable    = @config.searchable  ? false
    @pagination    = @config.pagination  ? true
    @reorderable   = @config.reorderable ? false
    @dataFetchLock = false
    @pagesCounter  = 0
    @searchQuery   = ''

    # if reorderable we need to set proper config for sorting
    if @reorderable
      @sortBy      = @reorderable.positionFieldName
      @sortReverse = @reorderable.sortReverse || false

    # bootstraped data provided
    if @config.data
      @pagesCounter = 1

  _addDataObjectToTheTop: (object, callback) ->
    @_map[object._id] = object
    @_data.unshift(object)
    position = 0
    $(this).trigger('object_added', { object: object, position: position, callback: callback })

  _wrapRailsObject: (object) ->
    # NOTE: generate form data object
    data = new FormData()
    for attr_name, attr_value of object
      # NOTE: special case for LIST inputs, values separated with comma
      if attr_name.indexOf('[__LIST__') > -1
        attr_name = attr_name.replace('__LIST__', '')
        values    = attr_value.split(',')
        for value in values
          data.append("#{ @config.resource }#{ attr_name }[]", value)
      else
        # NOTE: special case for FILE inputs
        if attr_name.startsWith('__FILE__')
          attr_name = attr_name.replace('__FILE__', '')

        data.append("#{ @config.resource }#{ attr_name }", attr_value)
    return data

  _urlWithParams: (url) ->
    if @config.urlParams
      extraParamString = $.param(@config.urlParams)
      if url.indexOf('?') > 0
        url = "#{ url }&#{ extraParamString }"
      else
        url = "#{ url }?#{ extraParamString }"
    return url

  _delete: (id, success) ->
    @dataFetchLock = true
    $.ajax
      type:     'DELETE'
      url:      @_urlWithParams("#{ @config.path }/#{ id }.json")
      success: (data, textStatus, jqXHR) =>
        @dataFetchLock = false
        success?(data)

  _post: (object, success, error) ->
    @dataFetchLock = true
    $.ajax
      type:        'POST'
      url:         @_urlWithParams("#{ @config.path }.json")
      data:        @_wrapRailsObject(object)
      processData: false
      contentType: false
      success: (data, textStatus, jqXHR) =>
        @dataFetchLock = false
        success?(data)
      error: (jqXHR, textStatus, errorThrown ) =>
        @dataFetchLock = false
        error?(jqXHR.responseJSON)

  _put: (id, object, success, error) ->
    @dataFetchLock = true
    $.ajax
      type:        'PUT'
      url:         @_urlWithParams("#{ @config.path }/#{ id }.json")
      data:        @_wrapRailsObject(object)
      processData: false
      contentType: false
      success: (data, textStatus, jqXHR) =>
        @dataFetchLock = false
        success?(data)
      error: (jqXHR, textStatus, errorThrown ) =>
        @dataFetchLock = false
        error?(jqXHR.responseJSON)

  _get: (params, success) ->
    @dataFetchLock = true
    $.get @_urlWithParams("#{ @config.path }.json"), params, (data) =>
      if data.length > 0
        @pagesCounter = @pagesCounter + 1
        for o in data
          @_addDataObject(o)

      @dataFetchLock = false
      success?()
      $(this).trigger('objects_added')

  #
  # PUBLIC
  #

  fetchNextPage: (callback) ->
    params = {}
    if @pagination
      params.page    = @pagesCounter + 1
      params.perPage = _itemsPerPageRequest
    if @searchQuery.length > 0
      params.search = @searchQuery
    @_get(params)

  search: (@searchQuery, callback) ->
    @pagesCounter = 0
    @_resetData()
    @fetchNextPage(callback)

  reset: (callback) ->
    @searchQuery  = ''
    @pagesCounter = 0
    @_resetData()
    @fetchNextPage(callback)

  update: (id, object, callbacks) ->
    @_put id, object, ((data) =>
      @_updateDataObject(id, data, callbacks.onSuccess)
    ), callbacks.onError

  push: (object, callbacks) ->
    @_post object, ((data) =>
      if @config.sortBy
        @_addDataObject(data, callbacks.onSuccess)
      else
        @_addDataObjectToTheTop(data, callbacks.onSuccess)
    ), callbacks.onError

  remove: (id) ->
    @_delete id, (data) =>
      @_removeDataObject(id)




