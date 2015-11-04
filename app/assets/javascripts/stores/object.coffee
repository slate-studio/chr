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
    @_initialize_store()


  # PRIVATE ===============================================

  _initialize_store: ->
    @_data = @config.data


  # PUBLIC ================================================

  loadObject: (callbacks={}) ->
    callbacks.onSuccess ?= $.noop
    callbacks.onSuccess(@_data)


  update: (id, value, callback) ->
    $.extend(@_data, value)
    callback?(@_data)




