# -----------------------------------------------------------------------------
# Author: Alexander Kravets <alex@slatestudio.com>,
#         Slate Studio (http://www.slatestudio.com)
#
# Coding Guide:
#   https://github.com/thoughtbot/guides/tree/master/style/coffeescript
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# VIEW LOCAL STORAGE
# -----------------------------------------------------------------------------
# @TODO: test how this works with nested forms
# -----------------------------------------------------------------------------

@viewLocalStorage =

  # PRIVATE ===============================================

  _bind_form_change: ->
    if typeof(Storage)
      @form.$el.on 'change', (e) => @_cache_form_state()
    else
      console.log ':: local storage is not supported ::'


  _cache_form_state: ->
    hash = @form.hash()
    json = JSON.stringify(hash)
    localStorage.setItem(@path, json)

    @$el.addClass 'has-unsaved-changes'


  _update_object_from_local_storage: ->
    if typeof(Storage)
      json = localStorage.getItem(@path)
      if json
        hash = JSON.parse(json)
        $.extend(@object, hash)

        @$el.addClass 'has-unsaved-changes'


  _changes_not_saved: ->
    if typeof(Storage)
      # if object is missing localStorage.getItem returns null
      if localStorage.getItem(@path) then true else false


  _clear_local_storage_cache: ->
    if typeof(Storage)
      localStorage.removeItem(@path)

      @$el.removeClass 'has-unsaved-changes'




