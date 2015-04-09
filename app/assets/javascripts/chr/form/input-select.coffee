# -----------------------------------------------------------------------------
# Author: Alexander Kravets <alex@slatestudio.com>,
#         Slate Studio (http://www.slatestudio.com)
#
# Coding Guide:
#   https://github.com/thoughtbot/guides/tree/master/style/coffeescript
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# INPUT SELECT
# -----------------------------------------------------------------------------

class @InputSelect extends InputString

  # PRIVATE ===============================================

  _create_el: ->
    @$el =$ "<div class='input-#{ @config.type } input-#{ @config.klass } #{ @config.klassName }'>"


  _add_input: ->
    @$input =$ """<select name='#{ @name }' id='#{ @name }'></select>"""
    @$el.append @$input

    @_add_options()


  _add_options: ->
    if @config.optionsHashFieldName
      @value = String(@value)
      if @object
        @config.optionsHash = @object[@config.optionsHashFieldName]
      else
        @config.optionsHash = { '': '--' }

    if @config.collection
      @_add_collection_options()

    else if @config.optionsList
      @_add_list_options()

    else if @config.optionsHash
      @_add_hash_options()


  _add_collection_options: ->
    for o in @config.collection.data
      title    = o[@config.collection.titleField]
      value    = o[@config.collection.valueField]
      @_add_option(title, value)


  _add_list_options: ->
    data = @config.optionsList
    for o in data
      @_add_option(o, o)


  _add_hash_options: ->
    data = @config.optionsHash
    for value, title of data
      @_add_option(title, value)


  _add_option: (title, value) ->
    selected = if @value == value then 'selected' else ''
    $option =$ """<option value='#{ value }' #{ selected }>#{ title }</option>"""
    @$input.append $option


  # PUBLIC ================================================

  updateValue: (@value, @object) ->
    @$input.html('')
    @_add_options()

    @$input.val(@value).prop('selected', true)


chr.formInputs['select'] = InputSelect




