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
      JSON.stringify(@value)
    else
      _escapeHtml(@value)


  # PUBLIC ================================================

  initialize: ->
    @config.onInitialize?(this)


  updateValue: (@value) ->
    @$el.val(@_safe_value())


  hash: (hash={}) ->
    hash[@config.klassName] = @$el.val()
    return hash


  showErrorMessage: (message) -> ;


  hideErrorMessage: -> ;


chr.formInputs['hidden'] = InputHidden




