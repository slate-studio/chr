# -----------------------------------------------------------------------------
# Author: Alexander Kravets <alex@slatestudio.com>,
#         Slate Studio (http://www.slatestudio.com)
#
# Coding Guide:
#   https://github.com/thoughtbot/guides/tree/master/style/coffeescript
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# RAILS ARRAY STORE
# -----------------------------------------------------------------------------
#
# Dependencies:
#= require ./rails-form-object-parser
#
# -----------------------------------------------------------------------------
class @RailsArrayStore extends RestArrayStore

  # PRIVATE ===============================================

  _configure_store: ->
    @ajaxConfig =
      processData: false
      contentType: false


  _resource_url: (type, id) ->
    objectPath = if id then "/#{ id }" else ''
    "#{ @config.path }#{ objectPath }.json"


include(RailsArrayStore, railsFormObjectParser)







