# -----------------------------------------------------------------------------
# Author: Alexander Kravets <alex@slatestudio.com>,
#         Slate Studio (http://www.slatestudio.com)
#
# Coding Guide:
#   https://github.com/thoughtbot/guides/tree/master/style/coffeescript
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# REST OBJECT STORE
# -----------------------------------------------------------------------------
class @RestObjectStore extends ObjectStore

  # PRIVATE ===============================================

  _initialize_store: ->
    @dataFetchLock = false
    @_configure_store()


  _configure_store: ->
    @ajaxConfig = {}


  # generate rest url for resource
  _resource_url: -> @config.path


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


  # do requests to database api
  _ajax: (type, data, success, error) ->
    options = $.extend @ajaxConfig,
      url:  @_resource_url()
      type: type
      data: data
      success: (data, textStatus, jqXHR) =>
        success?(data)
        @dataFetchLock = false
      error: (jqXHR, textStatus, errorThrown ) =>
        error?(jqXHR.responseJSON)
        @dataFetchLock = false

    @dataFetchLock = true
    $.ajax options


  # PUBLIC ================================================

  # load a single object, this is used in view when
  # store has not required item
  loadObject: (callbacks={}) ->
    callbacks.onSuccess ?= $.noop
    callbacks.onError   ?= $.noop

    @_ajax 'GET', null, ((data) =>
      callbacks.onSuccess(data)
    ), callbacks.onError


  # update objects attributes
  update: (id, serializedFormObject, callbacks={}) ->
    callbacks.onSuccess ?= $.noop
    callbacks.onError   ?= $.noop

    obj = @_parse_form_object(serializedFormObject)

    @_ajax 'PUT', obj, ((data) =>
      @_data = data
      callbacks.onSuccess(data)
    ), callbacks.onError




