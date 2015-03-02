# -----------------------------------------------------------------------------
# INPUT CHECKBOX
# -----------------------------------------------------------------------------
class @InputCheckbox extends InputString
  _safeValue: ->
    if not @value or @value == 'false' or @value == 0 or @value == '0'
      return false
    else
      return true

  _addInput: ->
    # NOTE: for boolean checkbox to be serialized correctly we need a hidden false
    #       value which is used by default and overriden by checked value
    @$false_hidden_input =$ "<input type='hidden' name='#{ @name }' value='false' />"
    @$el.append @$false_hidden_input

    @$input =$ "<input type='checkbox' name='#{ @name }' id='#{ @name }' value='true' #{ if @_safeValue() then 'checked' else '' } />"
    @$el.append @$input

  #
  # PUBLIC
  #

  constructor: (@name, @value, @config, @object) ->
    @$el =$ "<label for='#{ @name }' class='input-#{ @config.type } input-#{ @config.klass } #{ @config.klassName }'>"

    @_addInput()
    @_addLabel()

    return this

  updateValue: (@value) ->
    @$input.prop('checked', @_safeValue())

  hash: (hash={}) ->
    hash[@config.klassName] = @$input.prop('checked')
    return hash

_chrFormInputs['checkbox'] = InputCheckbox

# -----------------------------------------------------------------------------
# INPUT CHECKBOX SWITCH
# -----------------------------------------------------------------------------
class @InputCheckboxSwitch extends InputCheckbox
  _addInput: ->
    @$switch =$ "<div class='switch'>"
    @$el.append @$switch

    @$false_hidden_input =$ "<input type='hidden' name='#{ @name }' value='false' />"
    @$switch.append @$false_hidden_input

    @$input =$ "<input type='checkbox' name='#{ @name }' id='#{ @name }' value='true' #{ if @_safeValue() then 'checked' else '' } />"
    @$switch.append @$input

    @$checkbox =$ "<div class='checkbox'>"
    @$switch.append @$checkbox

  constructor: (@name, @value, @config, @object) ->
    @$el =$ "<label for='#{ @name }' class='input-#{ @config.type } input-#{ @config.klass } #{ @config.klassName }'>"

    @_addLabel()
    @_addInput()

    return this

_chrFormInputs['switch'] = InputCheckboxSwitch




