# -----------------------------------------------------------------------------
# FORM
# Generates form based on provided configuration schema.
# If schema is not provided generates default form based on object keys.
# -----------------------------------------------------------------------------

@_chrFormInputs ?= {}

class @Form
  constructor: (@object, @config) ->
    @groups    = []
    @inputs    = {}
    @$el       = $(@config.rootEl || '<form>')
    @schema    = @_getSchema()
    @isRemoved = false

    @_buildSchema(@schema, @$el)
    @_addNestedFormRemoveButton()


  # SCHEMA

  _getSchema: ->
    schema = @config.formSchema
    if @object
      schema ?= @_generateDefaultSchema()
    return schema


  _generateDefaultSchema: ->
    schema = {}
    for key, value of @object
      schema[key] = @_generateDefaultInputConfig(key, value)
    return schema


  _generateDefaultInputConfig: (fieldName, value) ->
    config = {}

    if fieldName[0] == '_'
      config.type = 'hidden'

    else if value in [ true, false ]
      config.type = 'checkbox'

    else if value

      if value.hasOwnProperty('url')
        config.type = 'file'

      else if value.length > 60
        config.type = 'text'

    return config


  #
  # INPUTS
  #

  _buildSchema: (schema, $el) ->
    for fieldName, config of schema
      if config.type == 'group'
        group = @_generateInputsGroup(fieldName, config)
        $el.append group.$el
      else
        input = @_generateInput(fieldName, config)
        $el.append input.$el


  _generateInputsGroup: (klassName, groupConfig) ->
    $group =$ """<div class='group #{ klassName }' />"""
    if groupConfig.inputs
      @_buildSchema(groupConfig.inputs, $group)
    group = { $el: $group, klassName: klassName, onInitialize: groupConfig.onInitialize }
    @groups.push group
    return group


  _generateInput: (fieldName, inputConfig) ->
    if @object
      value = @object[fieldName]
    else
      value = inputConfig.default

    value ?= ''

    inputName = inputConfig.name || fieldName
    input     = @_renderInput(inputName, inputConfig, value)
    @inputs[fieldName] = input
    return input


  _renderInput: (name, config, value) ->
    inputConfig = $.extend {}, config

    inputConfig.label    ?= @_titleizeLabel(name)
    inputConfig.type     ?= 'string'
    inputConfig.klass    ?= 'stacked'
    inputConfig.klassName = name

    inputClass  = _chrFormInputs[inputConfig.type]
    inputClass ?= _chrFormInputs['string']

    inputName = if @config.namePrefix then "#{ @config.namePrefix }[#{ name }]" else "[#{ name }]"

    # add prefix for nested form inputs
    if inputConfig.type == 'form'
      inputConfig.namePrefix = inputName.replace("[#{ name }]", "[#{name}_attributes]")
    else
      inputConfig.namePrefix = @config.namePrefix

    return new inputClass(inputName, value, inputConfig, @object)

  _titleizeLabel: (value) ->
    value.titleize().replace('Id', 'ID')


  #
  # NESTED
  #

  _addNestedFormRemoveButton: ->
    if @config.removeButton
      # add special hidden input to the form
      fieldName          = '_destroy'
      input              = @_renderInput(fieldName, { type: 'hidden' }, false)
      @inputs[fieldName] = input
      @$el.append input.$el
      # add button
      @$removeButton =$ """<a href='#' class='nested-form-delete'>Delete</a>"""
      @$el.append @$removeButton
      # handle click event
      @$removeButton.on 'click', (e) =>
        e.preventDefault()
        if confirm('Are you sure?')
          input.updateValue('true')
          @$el.hide()
          @isRemoved = true
          @config.onRemove?(this)


  _forms: ->
    forms = [ @ ]
    addNestedForms = (form) ->
      for name, input of form.inputs
        if input.config.type == 'form'
          forms = forms.concat(input.forms)
          addNestedForms(form) for form in input.forms
    addNestedForms(@)

    return forms


  # PUBLIC ================================================

  destroy: ->
    group.destroy?() for group in @groups
    input.destroy?() for name, input of @inputs
    @$el.remove()


  serialize: (obj={}) ->
    # serialize everything except file inputs
    obj[input.name] = input.value for input in @$el.serializeArray()

    for form in @_forms()
      # serialize file inputs for all forms (including nested)
      for name, input of form.inputs
        if input.config.type == 'file' or input.config.type == 'image'
          file = input.$input.get()[0].files[0]
          obj["__FILE__#{ input.name }"] = file

          # NOTE: when no file uploaded and no file selected, send
          #       remove flag so carrierwave does not catch _old_ value
          if not file and not input.filename then obj[input.removeName()] = 'true'

      # remove fields with ignoreOnSubmission
      for name, input of form.inputs
        if input.config.ignoreOnSubmission
          delete obj[name]

    return obj


  hash: (hash={}) ->
    for name, input of @inputs
      input.hash(hash)
    return hash


  initializePlugins: ->
    for group in @groups
      group.onInitialize?(@, group)

    for name, input of @inputs
      input.initialize()


  showValidationErrors: (errors) ->
    @hideValidationErrors()
    for inputName, messages of errors
      input        = @inputs[inputName]
      firstMessage = messages[0]
      input.showErrorMessage(firstMessage)


  hideValidationErrors: ->
    for inputName, input of @inputs
      input.hideErrorMessage()


  updateValues: (object) ->
    for name, value of object
      if @inputs[name]
        @inputs[name].updateValue(value, object)




