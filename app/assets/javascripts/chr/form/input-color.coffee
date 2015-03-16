# -----------------------------------------------------------------------------
# INPUT COLOR
# -----------------------------------------------------------------------------
class @InputColor extends InputString
  _addColorPreview: ->
    @$colorPreview =$ "<div class='preview'>"
    @$el.append @$colorPreview

  _updateColorPreview: ->
    @$colorPreview.css { 'background-color': "##{ @$input.val() }" }

  _validateInputValue: ->
    if (/^(?:[0-9a-f]{3}){1,2}$/i).test(@$input.val())
      @hideErrorMessage()
    else
      @showErrorMessage('Invalid hex value')

  initialize: ->
    @_addColorPreview()
    @_updateColorPreview()

    @$input.on 'change keyup',  (e) =>
      @hideErrorMessage()
      @_validateInputValue()
      @_updateColorPreview()

    @config.onInitialize?(this)


_chrFormInputs['color'] = InputColor





