# -----------------------------------------------------------------------------
# Author: Alexander Kravets <alex@slatestudio.com>,
#         Slate Studio (http://www.slatestudio.com)
#
# Coding Guide:
#   https://github.com/thoughtbot/guides/tree/master/style/coffeescript
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# INPUT FILE
# -----------------------------------------------------------------------------
class @InputFile extends InputString
  constructor: (@name, @value, @config, @object) ->
    @_create_el()

    @_add_label()
    @_add_input()
    @_update_state()

    return this


  # PRIVATE ===============================================

  _create_el: ->
    @$el =$ "<div class='input-#{ @config.type } input-#{ @config.klass } #{ @config.klassName }'>"


  _add_input: ->
    @$link =$ "<a href='#' target='_blank' title=''></a>"
    @$el.append(@$link)

    @$input =$ "<input type='file' name='#{ @name }' id='#{ @name }'>"
    @$el.append @$input

    @_add_remove_checkbox()


  _add_remove_checkbox: ->
    removeInputName     = @removeName()
    @$removeLabel       =$ "<label for='#{ removeInputName }'>Remove</label>"
    @$hiddenRemoveInput =$ "<input type='hidden' name='#{ removeInputName }' value='false'>"
    @$removeInput       =$ "<input type='checkbox' name='#{ removeInputName }' id='#{ removeInputName }' value='true'>"
    @$link.after(@$removeLabel)
    @$link.after(@$removeInput)
    @$link.after(@$hiddenRemoveInput)


  _update_inputs: ->
    @$link.html(@filename).attr('title', @filename).attr('href', @value.url)


  _update_state: (@filename=null) ->
    @$input.val('')
    @$removeInput.prop('checked', false)

    if @value.url
      @filename = _last(@value.url.split('/'))
      if @filename == '_old_' then @filename = null # carrierwave filename workaround

    if @filename
      @$el.removeClass('empty')
      @_update_inputs()
    else
      @$el.addClass('empty')


  # PUBLIC ================================================

  # when no file uploaded and no file selected, send remove flag so
  # carrierwave does not catch _old_ value
  isEmpty: ->
    ( ! @$input.get()[0].files[0] && ! @filename )


  removeName: ->
    @name.reverse().replace('[', '[remove_'.reverse()).reverse()


  updateValue: (@value, @object) ->
    @_update_state()


chr.formInputs['file'] = InputFile


# -----------------------------------------------------------------------------
# INPUT FILE IMAGE
# -----------------------------------------------------------------------------
# Config options:
#   thumbnail(object) - method that returns thumbnail for input
# -----------------------------------------------------------------------------
class @InputFileImage extends InputFile
  _add_input: ->
    @$link =$ "<a href='#' target='_blank' title=''></a>"
    @$el.append @$link

    @$thumb =$ "<img src='' />"
    @$el.append @$thumb

    @$input =$ "<input type='file' name='#{ @name }' id='#{ @name }' />"
    @$el.append @$input

    @_add_remove_checkbox()


  _update_inputs: ->
    @$link.html(@filename).attr('title', @filename).attr('href', @value.url)
    image_thumb_url = if @config.thumbnail then @config.thumbnail(@object) else @value.url
    @$thumb.attr('src', image_thumb_url).attr('alt', @filename)


chr.formInputs['image'] = InputFileImage




