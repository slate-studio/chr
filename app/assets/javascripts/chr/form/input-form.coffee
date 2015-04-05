# -----------------------------------------------------------------------------
# Author: Alexander Kravets <alex@slatestudio.com>,
#         Slate Studio (http://www.slatestudio.com)
#
# Coding Guide:
#   https://github.com/thoughtbot/guides/tree/master/style/coffeescript
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# INPUT "NESTED" FORM
# -----------------------------------------------------------------------------
# Name for this input comes from the Rails gem 'nested_forms'.
#
# Public methods:
#   initialize()
#   hash(hash)
#   updateValue(@value)
#   showErrorMessage(message)
#   hideErrorMessage()
#   addNewForm(object)
#
# Dependencies:
#= require ./input-form_reorder
#
# -----------------------------------------------------------------------------

class @InputForm
  constructor: (@name, @nestedObjects, @config, @object) ->
    @forms = []

    @config.namePrefix   ||= name
    @config.removeButton   = true
    @config.formSchema._id = { type: 'hidden', name: 'id' }
    @reorderContainerClass = "nested-forms-#{@config.klassName}"

    @_create_el()

    @_add_label()
    @_add_forms()
    @_add_new_button()

    return this


  # PRIVATE ===============================================

  _create_el: ->
    @$el =$ "<div class='input-stacked nested-forms #{ @config.klassName }'>"


  _add_label: ->
    @$label =$ "<span class='label'>#{ @config.label }</span>"
    @$errorMessage =$ "<span class='error-message'></span>"
    @$label.append(@$errorMessage)
    @$el.append(@$label)


  _add_forms: ->
    @$forms =$ "<ul>"
    @$label.after @$forms

    # if not default value which means no objects
    if @nestedObjects != ''
      @_sort_nested_objects()

      for i, object of @nestedObjects
        namePrefix = "#{ @config.namePrefix }[#{ i }]"
        @forms.push @_render_form(object, namePrefix, @config)

      @_bind_forms_reorder()


  _sort_nested_objects: ->
    if @config.sortBy
      @config.formSchema[@config.sortBy] = { type: 'hidden' }
      if @nestedObjects
        # this is not required but make things a bit easier on the backend
        # as object don't have to be in a specific order.
        @nestedObjects.sort (a, b) => parseFloat(a[@config.sortBy]) - parseFloat(b[@config.sortBy])
        # normalizes nested objects positions
        (o[@config.sortBy] = parseInt(i) + 1) for i, o of @nestedObjects


  _render_form: (object, namePrefix, config) ->
    formConfig = $.extend {}, config,
      namePrefix: namePrefix
      rootEl:     "<li>"

    form = new Form(object, formConfig)
    @$forms.append form.$el

    return form


  _add_new_button: ->
    label = @config.newButtonLabel || "Add"
    @$newButton =$ """<a href='#' class='nested-form-new'>#{ label }</a>"""
    @$el.append @$newButton
    @$newButton.on 'click', (e) => e.preventDefault() ; @addNewForm()


  # PUBLIC ================================================

  initialize: ->
    for nestedForm in @forms
      nestedForm.initializePlugins()
    @config.onInitialize?(this)


  hash: (hash={})->
    hash[@config.klassName] = []
    for form in @forms
      hash[@config.klassName].push form.hash()
    return hash


  showErrorMessage: (message) ->
    @$el.addClass 'error'
    @$errorMessage.html(message)


  hideErrorMessage: ->
    @$el.removeClass 'error'
    @$errorMessage.html('')


  addNewForm: (object=null) ->
    namePrefix    = "#{ @config.namePrefix }[#{ Date.now() }]"
    newFormConfig = $.extend({}, @config)

    delete newFormConfig.formSchema._id

    form = @_render_form(object, namePrefix, newFormConfig)
    form.initializePlugins()

    if @config.sortBy
      @_add_form_reorder_button(form)
      prevForm = _last(@forms)
      position = if prevForm then prevForm.inputs[@config.sortBy].value + 1 else 1
      form.inputs[@config.sortBy].updateValue(position)

    @forms.push(form)

    @config.onNew?(form)

    return form


  updateValue: (@nestedObjects, @object) ->
    @$forms.remove()
    @forms = []
    @_add_forms()


include(InputForm, inputFormReorder)


chr.formInputs['form'] = InputForm




