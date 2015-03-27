# -----------------------------------------------------------------------------
# Author: Alexander Kravets <alex@slatestudio.com>,
#         Slate Studio (http://www.slatestudio.com)
#
# Coding Guide:
#   https://github.com/thoughtbot/guides/tree/master/style/coffeescript
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# MONGOSTEEN (RAILS) OBJECT STORE IMPLEMENTATION
# -----------------------------------------------------------------------------
class @MongosteenObjectStore extends RestObjectStore
  # initial store configuration
  _initialize_database: ->
    @dataFetchLock = false
    @ajaxConfig =
      processData: false
      contentType: false


  # generate rest url for resource
  _resource_url: -> "#{ @config.path }.json"


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




