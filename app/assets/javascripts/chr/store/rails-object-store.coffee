# -----------------------------------------------------------------------------
# Author: Alexander Kravets <alex@slatestudio.com>,
#         Slate Studio (http://www.slatestudio.com)
#
# Coding Guide:
#   https://github.com/thoughtbot/guides/tree/master/style/coffeescript
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# RAILS OBJECT STORE
# -----------------------------------------------------------------------------
#
# Dependencies:
#= require ./_rails-form-object-parser
#
# -----------------------------------------------------------------------------
class @RailsObjectStore extends RestObjectStore

  # PRIVATE ===============================================

  _configure_store: ->
    @ajaxConfig =
      processData: false
      contentType: false


  _resource_url: ->
    "#{ @config.path }.json"


include(RailsObjectStore, railsFormObjectParser)




