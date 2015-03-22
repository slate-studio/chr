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

  _update_data_object: (value, callback) ->
    callback?($.extend(@_data, value))

  _fetch_data: ->
    @_data = @config.data

  _initialize_database: ->
    @_fetch_data()

  get: ->
    @_data

  update: (id, value, callback) ->
    @_update_data_object(value, callback)




