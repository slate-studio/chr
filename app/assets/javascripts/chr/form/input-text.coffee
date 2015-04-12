# -----------------------------------------------------------------------------
# Author: Alexander Kravets <alex@slatestudio.com>,
#         Slate Studio (http://www.slatestudio.com)
#
# Coding Guide:
#   https://github.com/thoughtbot/guides/tree/master/style/coffeescript
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# INPUT TEXT
# -----------------------------------------------------------------------------
#
# Dependencies:
#= require ../vendor/jquery.scrollparent
#= require ../vendor/jquery.textarea_autosize
#
# -----------------------------------------------------------------------------
class @InputText extends InputString

  # PRIVATE ===============================================

  _add_input: ->
    @$input =$ "<textarea class='autosize' name='#{ @name }' rows=1>#{ @_safe_value() }</textarea>"
    @$el.append @$input


  # PUBLIC ================================================

  initialize: ->
    @$input.textareaAutoSize()

    @config.onInitialize?(this)


chr.formInputs['text'] = InputText




