# -----------------------------------------------------------------------------
# INPUT STRING
# -----------------------------------------------------------------------------
class @InputString
  constructor: (@name, @value, @config, @object) ->
    @_createEl()
    @_addLabel()
    @_addInput()
    @_addPlaceholder()

    return this

  _createEl: ->
    @$el =$ "<label for='#{ @name }' class='input-#{ @config.type } input-#{ @config.klass } #{ @config.klassName }'>"

  _addLabel: ->
    if @config.klass in [ 'inline', 'stacked' ]
      @$label =$ "<span class='label'>#{ @config.label }</span>"
      @$el.append @$label

      @$errorMessage =$ "<span class='error-message'></span>"
      @$label.append @$errorMessage

  _addInput: ->
    @$input =$ "<input type='text' name='#{ @name }' value='#{ @_valueSafe() }' id='#{ @name }' />"
    @$el.append @$input

    if @config.options and $.isArray(@config.options)
      data = new Bloodhound
        datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value')
        queryTokenizer: Bloodhound.tokenizers.whitespace
        local:          $.map @config.options, (opt) -> { value: opt }

      data.initialize()

      @$input.typeahead({
        hint:      true
        highlight: true
        minLength: 1
      },
      {
        name:       'options'
        displayKey: 'value'
        source:     data.ttAdapter()
      })

  _valueSafe: ->
    if typeof(@value) == 'object'
      JSON.stringify(@value)
    else
      _escapeHtml(@value)

  _addPlaceholder: ->
    if @config.klass in [ 'placeholder', 'stacked' ]
      @$input.attr 'placeholder', @config.label

    if @config.placeholder
      @$input.attr 'placeholder', @config.placeholder

  #
  # PUBLIC
  #

  initialize: ->
    @config.onInitialize?(this)

  hash: (hash={}) ->
    hash[@config.klassName] = @$input.val()
    return hash

  updateValue: (@value) ->
    @$input.val(@value)

  showErrorMessage: (message) ->
    @$el.addClass 'error'
    @$errorMessage.html(message)

  hideErrorMessage: ->
    @$el.removeClass 'error'
    @$errorMessage.html('')


_chrFormInputs['string'] = InputString




