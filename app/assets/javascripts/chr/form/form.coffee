# -----------------------------------------------------------------------------
# Author: Alexander Kravets <alex@slatestudio.com>,
#         Slate Studio (http://www.slatestudio.com)
#
# Coding Guide:
#   https://github.com/thoughtbot/guides/tree/master/style/coffeescript
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# FORM
# -----------------------------------------------------------------------------
# Generates form based on provided configuration schema. If schema is not
# provided generates default form based on object keys. This uses Rails
# conventions for managing names for attributes, arrays, hashs and nested
# objects.
#
# -----------------------------------------------------------------------------

class @Form
  constructor: (@object, @config) ->
    @groups    = []
    @inputs    = {}
    @$el       = $(@config.rootEl || "<form class='form'>")
    @schema    = @_get_schema()
    @isRemoved = false

    @_build_schema(@schema, @$el)
    @_add_nested_form_remove_button()


  # PRIVATE ===============================================

  _get_schema: ->
    schema = @config.formSchema
    if @object
      schema ?= @_generate_default_schema()
    return schema


  _generate_default_schema: ->
    schema = {}
    for key, value of @object
      schema[key] = @_generate_default_input_config(key, value)
    return schema


  _generate_default_input_config: (fieldName, value) ->
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


  # INPUTS ================================================

  _build_schema: (schema, $el) ->
    for fieldName, config of schema
      if config.type == 'group'
        group = @_generate_inputs_group(fieldName, config)
        $el.append group.$el
      else
        input = @_generate_input(fieldName, config)
        $el.append input.$el


  _generate_inputs_group: (klassName, groupConfig) ->
    $group =$ """<div class='group #{ klassName }' />"""
    if groupConfig.inputs
      @_build_schema(groupConfig.inputs, $group)
    group = { $el: $group, klassName: klassName, onInitialize: groupConfig.onInitialize }
    @groups.push group
    return group


  _generate_input: (fieldName, inputConfig) ->
    if @object
      value = @object[fieldName]
    else
      value = inputConfig.default

    value ?= ''

    inputName = inputConfig.name || fieldName
    input     = @_render_input(inputName, inputConfig, value)
    @inputs[fieldName] = input
    return input


  _render_input: (name, config, value) ->
    inputConfig = $.extend {}, config

    inputConfig.label    ?= name.titleize()
    inputConfig.type     ?= 'string'
    inputConfig.klass    ?= 'stacked'
    inputConfig.klassName = name

    inputClass  = chr.formInputs[inputConfig.type]
    inputClass ?= chr.formInputs['string']

    inputName = if @config.namePrefix then "#{ @config.namePrefix }[#{ name }]" else "[#{ name }]"

    # add prefix for nested form inputs
    if inputConfig.type == 'form'
      inputConfig.namePrefix = inputName.replace("[#{ name }]", "[#{ name }_attributes]")
    else
      inputConfig.namePrefix = @config.namePrefix

    return new inputClass(inputName, value, inputConfig, @object)


  # NESTED ================================================

  _add_nested_form_remove_button: ->
    if @config.removeButton
      # add hidden input to the form
      fieldName          = '_destroy'
      input              = @_render_input(fieldName, { type: 'hidden' }, false)
      @inputs[fieldName] = input
      @$el.append input.$el
      # remove button
      @$removeButton =$ """<a href='#' class='nested-form-delete'>Delete</a>"""
      @$el.append @$removeButton
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
          if input.isEmpty() then obj[input.removeName()] = 'true'

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




