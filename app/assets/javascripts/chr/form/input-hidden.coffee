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
    # use textarea instead of regular input[type=hidden] to store HTML in there as well
    @$el =$ "<textarea style='display:none;' name='#{ @name }' rows=1>#{ @_safe_value() }</textarea>"


  _safe_value: ->
    if typeof(@value) == 'object'
      return JSON.stringify(@value)
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




