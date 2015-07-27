# -----------------------------------------------------------------------------
# Author: Alexander Kravets <alex@slatestudio.com>,
#         Slate Studio (http://www.slatestudio.com)
#
# Coding Guide:
#   https://github.com/thoughtbot/guides/tree/master/style/coffeescript
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# VIEW
# -----------------------------------------------------------------------------
#
# Config options:
#   formClass         - custom form class to be used
#   formSchema        - form schema for object, autogenerated if missing
#   disableDelete     - do not add delete button below the form
#   disableSave       - do not add save button in header
#   fullsizeView      — use fullsize layout in desktop mode
#   onViewShow        - on show callback
#   onSaveSuccess     - on document succesfully saved callback
#   defaultNewObject  - used to generate new form
#   disableFormCache  - do not cache form changes
#
# Public methods:
#   show(objectId)
#   destroy()
#   showSpinner()
#   hideSpinner()
#
# Dependencies:
#= require ./view_local-storage
#
# -----------------------------------------------------------------------------
class @View
  constructor: (@module, @config, @closePath, @listName) ->
    @store = @config.arrayStore ? @config.objectStore
    @path  = window.location.hash

    @$el =$ "<section class='view #{ @listName }'>"

    # fullsize
    if @config.fullsizeView
      @$el.addClass 'fullsize'

    # disable local storage cache, as that has to be
    # refactored to be more secure and obvious to user
    @config.disableFormCache ||= true

    # header
    @$header  =$ "<header class='header'></header>"
    @$spinner =$ "<div class='spinner'></div>"
    @$title   =$ "<div class='title'></div>"
    @$header.append @$spinner
    @$header.append @$title
    @$el.append @$header

    # close
    @$closeBtn =$ "<a href='#{ @closePath }' class='close'>Close</a>"
    @$closeBtn.on 'click', (e) => @_close(e)
    @$header.append @$closeBtn

    # content
    @$content =$ "<div class='content'></div>"
    @$el.append @$content


  # PRIVATE ===============================================

  _set_title: ->
    if ! @object
      title = "New"

    else if @config.objectStore
      title  = @config.title
      title ?= _firstNonEmptyValue(@object)

    else
      if @config.itemTitleField
        title = @object[@config.itemTitleField]
      title ?= @object['_list_item_title']
      title ?= _firstNonEmptyValue(@object)

    @$title.html(title.plainText())


  _add_delete_button: ->
    unless @config.disableDelete or @config.objectStore or (! @object)
      @$deleteBtn =$ "<a href='#' class='view-delete'>Delete</a>"
      @$deleteBtn.on 'click', (e) => @_delete(e)
      @$content.append @$deleteBtn


  _save_success: ->
    @$el.removeClass('view-saving')
    @_set_title()
    @form.hideValidationErrors()
    @form.updateValues(@object)
    @_clear_local_storage_cache()

    @config.onSaveSuccess?(@)


  _save_error: (message, validationErrors) ->
    @$el.removeClass('view-saving')
    @form.showValidationErrors(validationErrors)
    chr.showError(message)


  # EVENTS ================================================

  _close: (e) ->
    if @_changes_not_saved()
      if confirm('Your changes are not saved, still want to close?')
        @_clear_local_storage_cache()
      else
        e.preventDefault()


  _save: (e) ->
    e.preventDefault()
    @$el.addClass('view-saving')

    serializedFormObj = @form.serialize()

    if @object
      @store.update @object._id, serializedFormObj,
        onSuccess: (@object) =>
          @_save_success()
        onError: (errors) => @_save_error('Changes are not saved.', errors)
    else
      @store.push serializedFormObj,
        onSuccess: (@object) =>
          @_save_success()
          @_add_delete_button()
          chr.updateHash("#{ @closePath }/view/#{ @object._id }", true)
          @path = window.location.hash
          @config.onViewShow?(@)
        onError: (errors) => @_save_error('Document is not created due to an error.', errors)


  _delete: (e) ->
    e.preventDefault()
    if confirm("Are you sure?")
      @store.remove @object._id,
        onSuccess: =>
          @_clear_local_storage_cache()
          chr.updateHash("#{ @closePath }", true)
          @destroy()
          chr.mobileListLock(false)
        onError: -> chr.showError('Can\'t delete document.')


  _render_form: ->
    @_set_title()

    @hideSpinner()

    # save
    unless @config.disableSave
      @$saveBtn =$ "<a href='#' class='save'>Save</a>"
      @$saveBtn.on 'click', (e) => @_save(e)
      @$header.append @$saveBtn

    # sync with local storage cache
    if ! @config.disableFormCache
      @_update_object_from_local_storage()

    # form
    object = @object || @config.defaultNewObject || null
    @form  = new (@config.formClass ? Form)(object, @config)
    @$content.append @form.$el
    @form.initializePlugins()

    @_add_delete_button()
    @config.onViewShow?(@)

    # enable local storage caching
    if ! @config.disableFormCache
      @_bind_form_change()


  _show_error: ->
    @hideSpinner()
    chr.showError("can\'t show view for requested object, application error 500")


  # PUBLIC ================================================


  showSpinner: ->
    @$el.addClass('show-spinner')


  hideSpinner: ->
    @$el.removeClass('show-spinner')


  destroy: ->
    @form?.destroy()
    @$el.remove()


  show: (objectId) ->
    callbacks =
      onSuccess: (@object) => @_render_form()
      onError: => @_show_error()

    @showSpinner()

    # new for array store
    if objectId == null
      @object = null
      @_render_form()

    # object store
    else if objectId == ''
      @_set_title()
      @store.loadObject(callbacks)

    # array store
    else
      @store.loadObject(objectId, callbacks)


include(View, viewLocalStorage)




