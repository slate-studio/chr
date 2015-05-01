# -----------------------------------------------------------------------------
# Author: Alexander Kravets <alex@slatestudio.com>,
#         Slate Studio (http://www.slatestudio.com)
#
# Coding Guide:
#   https://github.com/thoughtbot/guides/tree/master/style/coffeescript
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# REST ARRAY STORE
# -----------------------------------------------------------------------------
#
# Config options:
#   pagination  - enable pagination for resource index, default `true`
#   searchable  - enable resource search, default `false`
#   urlParams   - additional parameter to be included into request
#
# Public methods:
#   loadObject
#   load
#   reset
#   search
#   push
#   update
#   remove
#
# -----------------------------------------------------------------------------
class @RestArrayStore extends ArrayStore

  # PRIVATE ===============================================

  _initialize_store: ->
    @dataFetchLock  = false
    @lastPageLoaded = false

    @searchable     = @config.searchable ? false
    @searchQuery    = ''

    @pagination     = @config.pagination ? true
    @nextPage       = 1
    @objectsPerPage = chr.itemsPerPageRequest ? 20

    @requestParams ?=
      page:    'page'
      perPage: 'perPage'
      search:  'search'

    @_configure_store()


  _configure_store: ->
    @ajaxConfig = {}


  # generate rest url for resource
  _resource_url: (type, id) ->
    objectPath = if id then "/#{ id }" else ''
    "#{ @config.path }#{ objectPath }"


  _request_url: (type, id) ->
    url = @_resource_url(type, id)

    if @config.urlParams
      extraParamsString = $.param(@config.urlParams)
      url = "#{ url }?#{ extraParamsString }"

    return url


  # do requests to database api
  _ajax: (type, id, data, success, error) ->
    options = $.extend @ajaxConfig,
      url:  @_request_url(type, id)
      type: type
      data: data
      success: (data, textStatus, jqXHR) =>
        success?(data)
        setTimeout ( => @dataFetchLock = false ), 50
      error: (jqXHR, textStatus, errorThrown ) =>
        error?(jqXHR.responseJSON)
        @dataFetchLock = false

    @dataFetchLock = true
    $.ajax options


  # check how this works with sorting enabled
  _sync_with_data_objects: (objects) ->
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


  # update next page counter and check if the last page was loaded
  _update_next_page: (data) ->
    if @pagination
      if data.length > 0
        @lastPageLoaded = true

        if data.length == @objectsPerPage
          @nextPage += 1
          @lastPageLoaded = false

      else
        @lastPageLoaded = true


  _is_pagination_edge_case: ->
    ( @pagination && @lastPageLoaded == false )


  _reload_current_page: (callbacks) ->
    @nextPage -= 1
    @load(true, callbacks)


  # PUBLIC ================================================

  # load a single object
  loadObject: (id, callbacks={}) ->
    callbacks.onSuccess ?= $.noop
    callbacks.onError   ?= $.noop

    @_ajax 'GET', id, null, ((data) =>
      object = @_normalize_object_id(data)
      callbacks.onSuccess(object)
    ), callbacks.onError


  # load next page objects from database and trigger 'objects_added' event
  load: (sync=false, callbacks={}) ->
    callbacks.onSuccess ?= $.noop
    callbacks.onError   ?= $.noop

    params = {}

    if @pagination
      params[@requestParams.page]    = @nextPage
      params[@requestParams.perPage] = @objectsPerPage

    if @searchable && @searchQuery.length > 0
      params[@requestParams.search]  = @searchQuery

    params = $.param(params)

    @_ajax 'GET', null, params, ((data) =>
      @_update_next_page(data)

      if sync
        @_sync_with_data_objects(data)
      else
        @_add_data_object(o) for o in data

      callbacks.onSuccess(data)

      $(this).trigger('objects_added', { objects: data })
    ), -> chr.showError('Error while loading data, application error 500.')


  # reset data and load again first page
  reset: (@searchQuery='') ->
    @lastPageLoaded = false
    @nextPage       = 1
    @load(true)


  # load search results first page
  search: (searchQuery) ->
    @reset(searchQuery)


  # add new object
  push: (serializedFormObject, callbacks={}) ->
    callbacks.onSuccess ?= $.noop
    callbacks.onError   ?= $.noop

    obj = @_parse_form_object(serializedFormObject)

    @_ajax 'POST', null, obj, ((data) =>
      d = @_add_data_object(data)

      if @_is_pagination_edge_case()
        if d.position >= (@nextPage - 1) * @objectsPerPage
          # if object added to the end of the list remove it
          @_remove_data_object(d.object._id)

      callbacks.onSuccess(data)

    ), callbacks.onError


  # update objects attributes
  update: (id, serializedFormObject, callbacks={}) ->
    callbacks.onSuccess ?= $.noop
    callbacks.onError   ?= $.noop

    obj = @_parse_form_object(serializedFormObject)

    @_ajax 'PUT', id, obj, ((data) =>
      d = @_update_data_object(id, data)

      if @_is_pagination_edge_case() && d.positionHasChanged
        if d.position >= (@nextPage - 1) * @objectsPerPage - 1

          console.log ':: reloading current page ::'
          # @TODO: test this scenario

          # if object added to the end of the list reload page to
          # sync last item on the page
          @_reload_current_page(callbacks)

      callbacks.onSuccess(data)

    ), callbacks.onError


  # delete object
  remove: (id, callbacks={}) ->
    callbacks.onSuccess ?= $.noop
    callbacks.onError   ?= $.noop

    @_ajax 'DELETE', id, {}, ( =>
      @_remove_data_object(id)

      if @_is_pagination_edge_case()
        # after item delete reload page to sync last item on the page
        @_reload_current_page(callbacks)

      else
        callbacks.onSuccess()

    ), callbacks.onError




