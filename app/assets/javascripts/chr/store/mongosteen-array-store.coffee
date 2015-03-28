# -----------------------------------------------------------------------------
# Author: Alexander Kravets <alex@slatestudio.com>,
#         Slate Studio (http://www.slatestudio.com)
#
# Coding Guide:
#   https://github.com/thoughtbot/guides/tree/master/style/coffeescript
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# MONGOSTEEN (RAILS) ARRAY/COLLECTION STORE IMPLEMENTATION
# this store implementation talks to Mongosteen powered Rails api, supports
# features:
#
#  - pagination
#    `sortBy` & `sortReverse` options should be set same as on
#    backend model with `default_scope` method (default), e.g:
#     - frontend: `{ sortBy: 'created_at', sortReverse: true }`
#     - backend:  `default_scope -> { desc(:created_at) }`
#
#  - search
#    backend model configuration required, e.g: `search_in :title`
# -----------------------------------------------------------------------------
class @MongosteenArrayStore extends RestArrayStore
  # initial store configuration
  _initialize_database: ->
    @dataFetchLock  = false
    @ajaxConfig =
      processData: false
      contentType: false

    @searchable   = @config.searchable ? false
    @searchQuery  = ''

    @pagination     = @config.pagination ? true
    @nextPage       = 1
    @objectsPerPage = _itemsPerPageRequest ? 20

    if @pagination
      @_bind_pagination_sync()


  # ---------------------------------------------------------
  # workarounds to have consistency between arrayStore and
  # database while loading next page
  # ---------------------------------------------------------
  _bind_pagination_sync: ->
    @lastPageLoaded = false

    # when object's added to the end of the list & not on the last page,
    # we don't know it's position on the backend, so remove it from store
    $(this).on 'object_added', (e, data) =>
      if ! @lastPageLoaded
        new_object          = data.object
        new_object_position = data.position

        # check if object added to the end of the list
        if new_object_position >= @objectsNumberForLoadedPages
          e.stopImmediatePropagation()

          @_remove_data_object(new_object._id)

    # when object's added to the end of the list & not on the last page,
    # we don't know it's position on the backend, so remove it from store
    $(this).on 'object_changed', (e, data) =>
      if ! @lastPageLoaded
        new_object          = data.object
        new_object_position = data.position

        # check if object added to the end of the list
        if new_object_position >= @objectsNumberForLoadedPages - 1
          e.stopImmediatePropagation()

          @_remove_data_object(new_object._id)

    # load current page again after item delete to sync, last item on the page
    $(this).on 'object_removed', (e, data) =>
      if ! @lastPageLoaded
        @_reload_current_page()


  _reload_current_page: ->
    @nextPage -= 1 ; @load()


  _udpate_next_page: (data) ->
    if @pagination
      if data.length > 0
        @lastPageLoaded = true

        if data.length == @objectsPerPage
          @nextPage += 1
          @lastPageLoaded = false

      else
        @lastPageLoaded = true

    @objectsNumberForLoadedPages = (@nextPage - 1) * @objectsPerPage


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


  # load results for search query
  search: (@searchQuery) ->
    @nextPage = 1
    @_reset_data()
    @load()


  # load next page objects from database, when finished
  # trigger 'objects_added' event
  load: (callbacks={}) ->
    callbacks.onSuccess ?= $.noop
    callbacks.onError   ?= $.noop

    params = {}

    if @pagination
      params.page    = @nextPage
      params.perPage = @objectsPerPage

    if @searchable && @searchQuery.length > 0
      params.search = @searchQuery

    params = $.param(params)

    @_ajax 'GET', null, params, ((data) =>
      @_udpate_next_page(data)
      @_add_data_object(o) for o in data

      callbacks.onSuccess(data)

      $(this).trigger('objects_added', { objects: data })
    ), callbacks.onError


  # reset data and load first page
  reset: ->
    @searchQuery = ''
    @nextPage    = 1
    params       = {}

    if @pagination
      @lastPageLoaded = false
      params.page     = @nextPage
      params.perPage  = @objectsPerPage

    params = $.param(params)

    @_ajax 'GET', null, params, ((data) =>
      @_udpate_next_page(data)
      @_sync_with_data_objects(data)

      $(this).trigger('objects_added', { objects: data })
    ), -> chr.showError('Error while loading data.')




