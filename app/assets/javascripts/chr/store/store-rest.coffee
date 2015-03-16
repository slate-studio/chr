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
class @RestArrayStore extends ArrayStore
  # initial store configuration
  _initialize_database: ->
    @dataFetchLock = false
    @ajaxConfig = {}


  # generate rest url for resource
  _resource_url: (type, id) ->
    objectPath = if id then "/#{ id }" else ''
    "#{ @config.path }#{ objectPath }"


  # do requests to database api
  _ajax: (type, id, data, success, error) ->
    options = $.extend @ajaxConfig,
      url:  @_resource_url(type, id)
      type: type
      data: data
      success: (data, textStatus, jqXHR) =>
        @dataFetchLock = false
        success?(data)
      error: (jqXHR, textStatus, errorThrown ) =>
        @dataFetchLock = false
        error?(jqXHR.responseJSON)

    @dataFetchLock = true
    $.ajax options


  # load objects from database, when finished
  # trigger 'objects_added' event
  load: (success) ->
    @_ajax 'GET', null, {}, ((dataObject) =>
      if dataObject.length > 0
        for o in dataObject
          @_add_data_object(o)

      success?()
      $(this).trigger('objects_added')
    ) #, callbacks.onError


  # add new object
  push: (serializedFormObject, callbacks) ->
    obj = @_parse_form_object(serializedFormObject)

    @_ajax 'POST', null, obj, ((dataObject) =>
      if @newItemOnTop
        @_add_data_object_on_top(dataObject, callbacks.onSuccess)
      else
        @_add_data_object(dataObject, callbacks.onSuccess)
    ), callbacks.onError


  # update objects attributes
  update: (id, serializedFormObject, callbacks) ->
    obj = @_parse_form_object(serializedFormObject)

    @_ajax 'PUT', id, obj, ((dataObject) =>
      @_update_data_object(id, dataObject, callbacks.onSuccess)
    ), callbacks.onError


  # delete object
  remove: (id) ->
    @_ajax 'DELETE', id, {}, ( =>
      @_remove_data_object(id)
    ), # callbacks.onError


  # reset all data and load it again
  reset: (callback) ->
    @_reset_data()
    @load(callback)




