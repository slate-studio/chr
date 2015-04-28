# -----------------------------------------------------------------------------
# Author: Alexander Kravets <alex@slatestudio.com>,
#         Slate Studio (http://www.slatestudio.com)
#
# Coding Guide:
#   https://github.com/thoughtbot/guides/tree/master/style/coffeescript
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# INPUT CHECKBOX
# -----------------------------------------------------------------------------
class @InputCheckbox extends InputString
  constructor: (@name, @value, @config, @object) ->
    @_create_el()
    @_add_input()
    @_add_label()

    return this


  # PRIVATE ===============================================

  _create_el: ->
    @$el =$ "<label for='#{ @name }' class='input-#{ @config.type } input-#{ @config.klass } input-#{ @config.klassName }'>"


  _safe_value: ->
    if not @value or @value == 'false' or @value == 0 or @value == '0'
      return false
    else
      return true


  _add_input: ->
    # for boolean checkbox to be serialized correctly we need a hidden false
    # value which is used by default and overriden by checked value
    @$false_hidden_input =$ "<input type='hidden' name='#{ @name }' value='false' />"
    @$el.append @$false_hidden_input

    @$input =$ "<input type='checkbox' id='#{ @name }' name='#{ @name }' value='true' #{ if @_safe_value() then 'checked' else '' } />"
    @$el.append @$input


  # PUBLIC ================================================

  updateValue: (@value) ->
    @$input.prop('checked', @_safe_value())


  hash: (hash={}) ->
    hash[@config.klassName] = @$input.prop('checked')
    return hash


chr.formInputs['checkbox'] = InputCheckbox


# -----------------------------------------------------------------------------
# INPUT CHECKBOX SWITCH
# -----------------------------------------------------------------------------
class @InputCheckboxSwitch extends InputCheckbox

  # PRIVATE ===============================================

  _add_input: ->
    @$switch =$ "<div class='switch'>"
    @$el.append @$switch

    @$false_hidden_input =$ "<input type='hidden' name='#{ @name }' value='false' />"
    @$switch.append @$false_hidden_input

    @$input =$ "<input type='checkbox' id='#{ @name }' name='#{ @name }' value='true' #{ if @_safe_value() then 'checked' else '' } />"
    @$switch.append @$input

    @$checkbox =$ "<div class='checkbox'>"
    @$switch.append @$checkbox


chr.formInputs['switch'] = InputCheckboxSwitch




