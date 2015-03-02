# -----------------------------------------------------------------------------
# INPUT HIDDEN
# -----------------------------------------------------------------------------
class @InputHidden
  constructor: (@name, @value, @config, @object) ->
    @$el = $("<input type='hidden' name='#{ @name }' value='#{ @_valueSafe() }' id='#{ @name }' />")

    return this

  _valueSafe: ->
    if typeof(@value) == 'object'
      JSON.stringify(@value)
    else
      _escapeHtml(@value)

  #
  # PUBLIC
  #

  initialize: ->
    @config.onInitialize?(this)

  updateValue: (@value) ->
    @$el.val(@_valueSafe())

  hash: (hash={}) ->
    hash[@config.klassName] = @$el.val()
    return hash

  showErrorMessage: (message) ->
    ;

  hideErrorMessage: ->
    ;


_chrFormInputs['hidden'] = InputHidden




