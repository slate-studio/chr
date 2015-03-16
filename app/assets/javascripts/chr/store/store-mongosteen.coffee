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

    @pagination   = @config.pagination ? true
    @pagesCounter = 0

    # disable pagination when bootstraped data provided
    if @config.data
      @pagination = false


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


  # load next page objects from database, when finished
  # trigger 'objects_added' event
  load: (success) ->
    params = {}

    if @pagination
      params.page    = @pagesCounter + 1
      params.perPage = _itemsPerPageRequest ? 20

    if @searchable && @searchQuery.length > 0
      params.search = @searchQuery

    params = $.param(params)

    @_ajax 'GET', null, params, ((dataObject) =>
      if dataObject.length > 0
        @pagesCounter = @pagesCounter + 1

        for o in dataObject
          @_add_data_object(o)

      success?()
      $(this).trigger('objects_added')
    ) #, callbacks.onError


  # load results for search query
  search: (@searchQuery, callback) ->
    @pagesCounter = 0
    @_reset_data()
    @load(callback)


  # reset data and load first page
  reset: (callback) ->
    @searchQuery  = ''
    @pagesCounter = 0
    @_reset_data()
    @load(callback)




