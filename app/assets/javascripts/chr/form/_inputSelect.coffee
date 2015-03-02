# -----------------------------------------------------------------------------
# INPUT SELECT
# -----------------------------------------------------------------------------
class @InputSelect extends InputString
  _createEl: ->
    @$el =$ "<div class='input-#{ @config.type } input-#{ @config.klass } #{ @config.klassName }'>"

  _addOption: (title, value) ->
    selected = if @value == value then 'selected' else ''
    $option =$ """<option value='#{ value }' #{ selected }>#{ title }</option>"""
    @$input.append $option

  _addListOptions: ->
    data = @config.optionsList
    for o in data
      @_addOption(o, o)

  _addHashOptions: ->
    data = @config.optionsHash
    for value, title of data
      @_addOption(title, value)

  _addCollectionOptions: ->
    data       = @config.collection.data
    valueField = @config.collection.valueField
    titleField = @config.collection.titleField

    for o in data
      title    = o[titleField]
      value    = o[valueField]
      @_addOption(title, value)

  _addOptions: ->
    if @config.collection
      @_addCollectionOptions()
    else if @config.optionsList
      @_addListOptions()
    else if @config.optionsHash
      @_addHashOptions()

  _addInput: ->
    @$input =$ """<select name='#{ @name }' id='#{ @name }'></select>"""
    @$el.append @$input

    if @config.optionsHashFieldName
      @value = String(@value)
      if @object
        @config.optionsHash = @object[@config.optionsHashFieldName]
      else
        @config.optionsHash = { '': '--' }

    @_addOptions()


_chrFormInputs['select'] = InputSelect




