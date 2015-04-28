# -----------------------------------------------------------------------------
# Author: Alexander Kravets <alex@slatestudio.com>,
#         Slate Studio (http://www.slatestudio.com)
#
# Coding Guide:
#   https://github.com/thoughtbot/guides/tree/master/style/coffeescript
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# INPUT HIDDEN
# -----------------------------------------------------------------------------
class @InputHidden
  constructor: (@name, @value, @config, @object) ->
    @_create_el()

    return this


  # PRIVATE ===============================================

  _create_el: ->
    @$el =$ "<input type='hidden' name='#{ @name }' value='#{ @_safe_value() }' />"


  _safe_value: ->
    if typeof(@value) == 'object'
      return JSON.stringify(@value)
    else
      _escapeHtml(@value)


  # PUBLIC ================================================

  showErrorMessage: (message) -> ;


  hideErrorMessage: -> ;


  initialize: ->
    @config.onInitialize?(this)


  hash: (hash={}) ->
    hash[@config.klassName] = @$el.val()
    return hash


  updateValue: (@value) ->
    @$el.val(@value)


chr.formInputs['hidden'] = InputHidden




