# -----------------------------------------------------------------------------
# VIEW
# -----------------------------------------------------------------------------
class @View
  _renderForm: ->
    @form?.destroy()
    @form = new Form(@object, @config)

    unless @config.disableDelete or @config.objectStore or @_isNew()
      @$deleteBtn =$ "<a href='#' class='delete'>Delete</a>"
      @$deleteBtn.on 'click', (e) => @onDelete(e)
      @form.$el.append @$deleteBtn

    @$el.append @form.$el

  _render: ->
    title  = @title
    title ?= @object[@config.itemTitleField] if @config.itemTitleField
    title ?= _firstNonEmptyValue(@object)
    if title == "" then title = "No Title"

    # NOTE: remove html tags from title to do not break layout
    titleText = $("<div>#{ title }</div>").text()
    @$title.html(titleText)

    @_renderForm()

  _initializeFormPlugins: ->
    # NOTE: we might need a callback here to workaround plugins blink issue, by setting
    #       form opacity to 0 and then fading to 1 after plugins are ready.
    @form.initializePlugins()
    @config.onViewShow?(@)

  _updateObject: (value) ->
    @$el.addClass('view-saving')
    @store.update @object._id, value,
      onSuccess: (object) =>
        # TODO: add a note here for this line, it's not obvious why it's here,
        #       looks like some logic related to title update
        if @config.arrayStore then @title = null

        formScrollPosition = @form.$el.scrollTop()
        @_render()
        @_initializeFormPlugins()
        @form.$el.scrollTop(formScrollPosition)

        setTimeout ( => @$el.removeClass('view-saving') ), 250
      onError: (errors) =>
        @validationErrors(errors)
        setTimeout ( => @$el.removeClass('view-saving') ), 250

  _createObject: (value) ->
    @$el.addClass('view-saving')
    @store.push value,
      onSuccess: (object) =>
        # NOTE: jump to the newely created item, added to the top of the list by default
        location.hash = "#/#{ @closePath }/view/#{ object._id }"
      onError: (errors) =>
        @validationErrors(errors)
        setTimeout ( => @$el.removeClass('view-saving') ), 250

  _isNew: -> not @object

  constructor: (@module, @config, @closePath, @object, @title) ->
    @store = @config.arrayStore ? @config.objectStore

    @$el =$ "<section class='view #{ @module.name }'>"
    @$el.hide()

    @$header =$ "<header></header>"
    @$title  =$ "<div class='title'></div>"
    @$header.append @$title

    @$closeBtn =$ "<a href='#/#{ @closePath }' class='close silent'>Close</a>"
    @$closeBtn.on 'click', (e) => @onClose(e)
    @$header.append @$closeBtn

    unless @config.disableSave
      @$saveBtn =$ "<a href='#' class='save'>Save</a>"
      @$saveBtn.on 'click', (e) => @onSave(e)
      @$header.append @$saveBtn

    @$el.append @$header

    @_render()

  show: (animate, callback) ->
    if animate
      @$el.fadeIn($.fx.speeds._default, => @_initializeFormPlugins() ; callback?())
    else
      @$el.show 0, => @_initializeFormPlugins() ; callback?()

  destroy: ->
    @form?.destroy()
    @$el.remove()

  onClose: (e) ->
    @module.unselectActiveListItem()
    @$el.fadeOut $.fx.speeds._default, => @destroy()

  onSave: (e) ->
    e.preventDefault()
    serializedObj = @form.serialize()
    if @object then @_updateObject(serializedObj) else @_createObject(serializedObj)

  onDelete: (e) ->
    e.preventDefault()
    if confirm("Are you sure?")
      @store.remove(@object._id)
      @$el.fadeOut $.fx.speeds._default, =>
        window._skipHashchange = true
        location.hash = "#/#{ @closePath }"
        @destroy()

  validationErrors: (errors) ->
    @form.showValidationErrors(errors)





