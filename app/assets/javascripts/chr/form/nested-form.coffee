# -----------------------------------------------------------------------------
# NESTED FORM
# -----------------------------------------------------------------------------
class @NestedForm
  constructor: (@name, @nestedObjects, @config, @object) ->
    @forms = []

    @config.namePrefix  ||= name
    @config.removeButton  = true
    @config.formSchema.id = { type: 'hidden' }
    @reorderContainerClass = "nested-forms-#{@config.klassName}"

    if @config.sortBy
      @config.formSchema[@config.sortBy] = { type: 'hidden' }
      if @nestedObjects
        # NOTE: this is not required but make things a bit easier on the backend
        #       as object don't have to be in a specific order.
        @nestedObjects.sort (a, b) => parseFloat(a[@config.sortBy]) - parseFloat(b[@config.sortBy])
        # NOTE: normalizes nested objects positions
        (o[@config.sortBy] = parseInt(i) + 1) for i, o of @nestedObjects

    @$el =$ "<div class='input-stacked nested-forms #{ @config.klassName }'>"

    @_addLabel()
    @_addForms()
    @_addFormsReorder()
    @_addNewButton()

    return this

  _addLabel: ->
    if @config.klass in [ 'inline', 'stacked' ]
      @$label =$ "<span class='label'>#{ @config.label }</span>"
      @$el.append @$label

      @$errorMessage =$ "<span class='error-message'></span>"
      @$label.append @$errorMessage

  _addForms: ->
    @$forms =$ "<ul>"
    @$el.append @$forms

    # if not default value which means no objects
    if @nestedObjects != ''
      for i, object of @nestedObjects
        namePrefix = "#{ @config.namePrefix }[#{ i }]"
        @forms.push @_renderForm(object, namePrefix, @config)

  _renderForm: (object, namePrefix, config) ->
    formConfig = $.extend {}, config,
      namePrefix: namePrefix
      rootEl:     "<li>"

    form = new Form(object, formConfig)
    @$forms.append form.$el

    return form

  _addFormsReorder: ->
    if @config.sortBy
      list = @$forms.addClass(@reorderContainerClass).get(0)

      new Slip(list)

      list.addEventListener 'slip:beforeswipe', (e) -> e.preventDefault()

      list.addEventListener 'slip:beforewait', ((e) ->
        if $(e.target).hasClass("icon-reorder") then e.preventDefault()
      ), false

      list.addEventListener 'slip:beforereorder', ((e) ->
        if not $(e.target).hasClass("icon-reorder") then e.preventDefault()
      ), false

      list.addEventListener 'slip:reorder', ((e) =>
        # NOTE: this event called for all parent lists, add a check for context:
        #       process this event only if target form is in the @forms list.
        targetForm = @_findFormByTarget(e.target)
        if targetForm
          # NOTE: when `e.detail.insertBefore` is null, item put to the end of the list.
          e.target.parentNode.insertBefore(e.target, e.detail.insertBefore)

          $targetForm =$ e.target
          prevForm    = @_findFormByTarget($targetForm.prev().get(0))
          nextForm    = @_findFormByTarget($targetForm.next().get(0))

          prevFormPosition      = if prevForm then prevForm.inputs[@config.sortBy].value else 0
          nextFormPosition      = if nextForm then nextForm.inputs[@config.sortBy].value else 0
          newTargetFormPosition = prevFormPosition + Math.abs(nextFormPosition - prevFormPosition) / 2.0

          targetForm.inputs[@config.sortBy].updateValue(newTargetFormPosition)

        return false
      ), false

      @_addFormReorderButton(form) for form in @forms

  _addFormReorderButton: (form) ->
    form.$el.append("""<div class='icon-reorder' data-container-class='#{@reorderContainerClass}'></div>""").addClass('reorderable')

  _findFormByTarget: (el) ->
    if el
      for form in @forms
        if form.$el.get(0) == el then return form
    return null

  _addNewButton: ->
    label = @config.newButtonLabel || "Add"
    @$newButton =$ """<a href='#' class='nested-form-new'>#{ label }</a>"""
    @$el.append @$newButton
    @$newButton.on 'click', (e) => e.preventDefault() ; @addNewForm()

  #
  # PUBLIC
  #

  addNewForm: (object=null) ->
    namePrefix    = "#{ @config.namePrefix }[#{ Date.now() }]"
    newFormConfig = $.extend({}, @config)

    delete newFormConfig.formSchema.id

    form = @_renderForm(object, namePrefix, newFormConfig)
    form.initializePlugins()

    if @config.sortBy
      @_addFormReorderButton(form)
      prevForm = _last(@forms)
      position = if prevForm then prevForm.inputs[@config.sortBy].value + 1 else 1
      form.inputs[@config.sortBy].updateValue(position)

    @forms.push(form)

    @config.onNew?(form)

    return form

  initialize: ->
    for nestedForm in @forms
      nestedForm.initializePlugins()
    @config.onInitialize?(this)

  showErrorMessage: (message) ->
    @$el.addClass 'error'
    @$errorMessage.html(message)

  hideErrorMessage: ->
    @$el.removeClass 'error'
    @$errorMessage.html('')

  updateValue: (@value) ->
    # TODO: update

  hash: (hash={})->
    hash[@config.klassName] = []
    for form in @forms
      hash[@config.klassName].push form.hash()
    return hash


_chrFormInputs['form'] = NestedForm




