# -----------------------------------------------------------------------------
# Author: Alexander Kravets <alex@slatestudio.com>,
#         Slate Studio (http://www.slatestudio.com)
#
# Coding Guide:
#   https://github.com/thoughtbot/guides/tree/master/style/coffeescript
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# MONGOSTEEN (RAILS) ARRAY/COLLECTION STORE IMPLEMENTATION
# -----------------------------------------------------------------------------
class @MongosteenArrayStore extends RestArrayStore
  # initial store configuration
  _initialize_database: ->
    @dataFetchLock = false
    @ajaxConfig =
      processData: false
      contentType: false

    @searchable   = @config.searchable ? false
    @searchQuery  = ''

    @pagination     = @config.pagination ? true
    @pagesCounter   = 0
    @objectsPerPage = _itemsPerPageRequest ? 20

    # disable pagination when bootstraped data provided
    if @config.data
      @pagination = false


  # ---------------------------------------------------------
  # workarounds to have consistency between arrayStore and
  # database while loading next page:
  #  - add new item: don't add if added to the bottom of the
  #                  store, otherwise remove last object in store
  #  - remove item:  load one object based on offset
  #  - update item:  if item is last in the store after update,
  #                  remove it and load last object again
  # ---------------------------------------------------------


  # generate resource api url
  _resource_url: (type, id) ->
    objectPath = if id then "/#{ id }" else ''
    url = "#{ @config.path }#{ objectPath }.json"

    if @config.urlParams
      extraParamsString = $.param(@config.urlParams)
      url = "#{ url }?#{ extraParamsString }"

    return url


  # get form data object from serialized form object,
  # it uses special format for object names for support of:
  # files, lists, nested objects
  _parse_form_object: (serializedFormObject) ->
    formDataObject = new FormData()

    for attr_name, attr_value of serializedFormObject

      # special case for LIST inputs, values separated with comma
      if attr_name.indexOf('[__LIST__') > -1
        attr_name = attr_name.replace('__LIST__', '')
        values    = attr_value.split(',')

        for value in values
          formDataObject.append("#{ @config.resource }#{ attr_name }[]", value)

      else
        # special case for FILE inputs
        if attr_name.startsWith('__FILE__')
          attr_name = attr_name.replace('__FILE__', '')

        formDataObject.append("#{ @config.resource }#{ attr_name }", attr_value)

    return formDataObject


  # check how this works with sorting enabled
  _sync_data_objects: (objects) ->
    if objects.length == 0 then return @_reset_data()
    if @_data.length  == 0 then return ( @_add_data_object(o) for o in objects )

    objectsMap = {}
    (o = @_normalize_object_id(o) ; objectsMap[o._id] = o) for o in objects

    objectIds     = $.map objects, (o) -> o._id
    dataObjectIds = $.map @_data,  (o) -> o._id

    addObjectIds        = $(objectIds).not(dataObjectIds).get()
    updateDataObjectIds = $(objectIds).not(addObjectIds).get()
    removeDataObjectIds = $(dataObjectIds).not(objectIds).get()

    for id in removeDataObjectIds
      @_remove_data_object(id)

    for id in addObjectIds
      @_add_data_object(objectsMap[id])

    for id in updateDataObjectIds
      @_update_data_object(id, objectsMap[id])


  # load next page objects from database, when finished
  # trigger 'objects_added' event
  load: (callbacks={}) ->
    callbacks.onSuccess ?= $.noop
    callbacks.onError   ?= $.noop

    params = {}

    if @pagination
      params.page    = @pagesCounter + 1
      params.perPage = @objectsPerPage

    if @searchable && @searchQuery.length > 0
      params.search = @searchQuery

    params = $.param(params)

    @_ajax 'GET', null, params, ((data) =>
      if data.length > 0
        @pagesCounter = @pagesCounter + 1
        @_add_data_object(o) for o in data

      callbacks.onSuccess(data)

      $(this).trigger('objects_added', { objects: data })
    ), callbacks.onError


  # load results for search query
  search: (@searchQuery) ->
    @pagesCounter = 0
    @_reset_data()
    @load()


  # reset data and load first page
  reset: (force=false) ->
    @searchQuery  = ''
    @pagesCounter = 0

    if force
      @_reset_data()
      @load()
    else
      params = {}

      if @pagination
        params.page    = @pagesCounter + 1
        params.perPage = @objectsPerPage

      params = $.param(params)

      @_ajax 'GET', null, params, ((data) =>
        if data.length > 0
          @pagesCounter = @pagesCounter + 1
        @_sync_data_objects(data)
        $(this).trigger('objects_added', { objects: data })
      ), -> chr.showError('Error while loading data.')




