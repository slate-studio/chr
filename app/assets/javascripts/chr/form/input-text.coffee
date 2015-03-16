# -----------------------------------------------------------------------------
# INPUT TEXT
# Dependencies:
#  - jquery.textaread_autosize.js (https://github.com/javierjulio/textarea-autosize)
#  - bugfix: https://github.com/javierjulio/textarea-autosize/issues/8#issuecomment-67300688
# -----------------------------------------------------------------------------
class @InputText extends InputString
  _addInput: ->
    @$input =$ "<textarea class='autosize' name='#{ @name }' id='#{ @name }' rows=1>#{ @_valueSafe() }</textarea>"
    @$el.append @$input

  initialize: ->
    # TODO: refactor a bit plugin code so there is no blink while jumping from object to object
    @$input.textareaAutoSize()

    @config.onInitialize?(this)


_chrFormInputs['text'] = InputText




