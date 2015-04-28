# -----------------------------------------------------------------------------
# Author: Alexander Kravets <alex@slatestudio.com>,
#         Slate Studio (http://www.slatestudio.com)
#
# Coding Guide:
#   https://github.com/thoughtbot/guides/tree/master/style/coffeescript
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# INPUT COLOR
# -----------------------------------------------------------------------------
class @InputColor extends InputString

  # PRIVATE ===============================================

  _add_color_preview: ->
    @$colorPreview =$ "<div class='preview'>"
    @$el.append @$colorPreview


  _update_color_preview: ->
    @$colorPreview.css { 'background-color': "##{ @$input.val() }" }


  _validate_input_value: ->
    if (/^(?:[0-9a-f]{3}){1,2}$/i).test(@$input.val())
      @hideErrorMessage()
    else
      @showErrorMessage('Invalid hex value')


  # PUBLIC ================================================

  initialize: ->
    @$input.attr('placeholder', @config.placeholder || 'e.g. #eee')

    @_add_color_preview()
    @_update_color_preview()

    @$input.on 'change keyup',  (e) =>
      @hideErrorMessage()
      @_validate_input_value()
      @_update_color_preview()

    @config.onInitialize?(this)


chr.formInputs['color'] = InputColor





