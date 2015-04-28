# -----------------------------------------------------------------------------
# Author: Alexander Kravets <alex@slatestudio.com>,
#         Slate Studio (http://www.slatestudio.com)
#
# Coding Guide:
#   https://github.com/thoughtbot/guides/tree/master/style/coffeescript
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# INPUT "NESTED" FORM REORDER
# -----------------------------------------------------------------------------

@inputFormReorder =
  # PRIVATE ===============================================

  _bind_forms_reorder: ->
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
        # this event called for all parent lists, add a check for context:
        # process this event only if target form is in the @forms list.
        targetForm = @_find_form_by_target(e.target)
        if targetForm
          # when `e.detail.insertBefore` is null, item put to the end of the list.
          e.target.parentNode.insertBefore(e.target, e.detail.insertBefore)

          $targetForm =$ e.target
          prevForm    = @_find_form_by_target($targetForm.prev().get(0))
          nextForm    = @_find_form_by_target($targetForm.next().get(0))

          prevFormPosition      = if prevForm then prevForm.inputs[@config.sortBy].value else 0
          nextFormPosition      = if nextForm then nextForm.inputs[@config.sortBy].value else 0
          newTargetFormPosition = prevFormPosition + Math.abs(nextFormPosition - prevFormPosition) / 2.0

          targetForm.inputs[@config.sortBy].updateValue(newTargetFormPosition)

        return false
      ), false

      @_add_form_reorder_button(form) for form in @forms


  _add_form_reorder_button: (form) ->
    form.$el.append("""<div class='icon-reorder' data-container-class='#{@reorderContainerClass}'></div>""").addClass('reorderable')


  _find_form_by_target: (el) ->
    if el
      for form in @forms
        if form.$el.get(0) == el then return form
    return null



