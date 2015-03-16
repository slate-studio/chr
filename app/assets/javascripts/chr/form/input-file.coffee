# -----------------------------------------------------------------------------
# INPUT FILE
# -----------------------------------------------------------------------------
class @InputFile extends InputString
  _addInput: ->
    @$el.addClass 'empty'
    if @filename
      @$link =$ "<a href='#{ @value.url }' target='_blank' title='#{ @filename }'>#{ @filename }</a>"
      @$el.append @$link
      @$el.removeClass 'empty'

    @$input =$ "<input type='file' name='#{ @name }' id='#{ @name }' />"
    @$el.append @$input

  _addRemoveCheckbox: ->
    # NOTE: this is Rails (CarrierWave) approach to remove files, might not be
    #       generic, so we should consider to move it to store.
    if @filename
      removeInputName = @removeName()

      @$removeLabel =$ "<label for='#{ removeInputName }'>Remove</label>"
      @$link.after @$removeLabel

      @$hiddenRemoveInput =$ "<input type='hidden' name='#{ removeInputName }' value='false'>"
      @$removeInput       =$ "<input type='checkbox' name='#{ removeInputName }' id='#{ removeInputName }' value='true'>"

      @$link.after @$removeInput
      @$link.after @$hiddenRemoveInput

  constructor: (@name, @value, @config, @object) ->
    @$el =$ "<div class='input-#{ @config.type } input-#{ @config.klass } #{ @config.klassName }'>"

    # NOTE: carrierwave filename workaround
    @filename = null
    if @value.url
      @filename = _last(@value.url.split('/'))
      if @filename == '_old_' then @filename = null

    @_addLabel()
    @_addInput()
    @_addRemoveCheckbox()

    return this

  removeName: -> @name.reverse().replace('[', '[remove_'.reverse()).reverse()

  updateValue: (@value) ->
    # TODO: this method required to enable version switch for objects history


_chrFormInputs['file'] = InputFile

# -----------------------------------------------------------------------------
# INPUT FILE IMAGE
# -----------------------------------------------------------------------------
class @InputFileImage extends InputFile
  _addInput: ->
    @$el.addClass 'empty'
    if @filename
      @$link =$ "<a href='#{ @value.url }' target='_blank' title='#{ @filename }'>#{ @filename }</a>"
      @$el.append @$link

      thumbnailImageUrl = @value.url
      thumbnailImage = @value[@config.thumbnailFieldName]

      if thumbnailImage
        thumbnailImageUrl = thumbnailImage.url

      @$thumb =$ "<img src='#{ thumbnailImageUrl }' />"
      @$el.append @$thumb

      @$el.removeClass 'empty'

    @$input =$ "<input type='file' name='#{ @name }' id='#{ @name }' />"
    @$el.append @$input


_chrFormInputs['image'] = InputFileImage




