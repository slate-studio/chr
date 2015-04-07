# -----------------------------------------------------------------------------
# Author: Alexander Kravets <alex@slatestudio.com>,
#         Slate Studio (http://www.slatestudio.com)
#
# Coding Guide:
#   https://github.com/thoughtbot/guides/tree/master/style/coffeescript
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# OBJECT STORE
# -----------------------------------------------------------------------------
class @ObjectStore
  constructor: (@config={}) ->
    @_initialize_database()

  # PRIVATE ===============================================

  _initialize_database: ->
    @_data = @config.data


  # PUBLIC ================================================

  loadObject: ->
    @_data


  update: (id, value, callback) ->
    $.extend(@_data, value)
    callback?(@_data)




