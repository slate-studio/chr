# -----------------------------------------------------------------------------
# Author: Alexander Kravets <alex@slatestudio.com>,
#         Slate Studio (http://www.slatestudio.com)
#
# Coding Guide:
#   https://github.com/thoughtbot/guides/tree/master/style/coffeescript
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# INPUT LIST REORDER
# -----------------------------------------------------------------------------

@inputListReorder =
  # PRIVATE ===============================================
  _bind_reorder: ->
    list = @$items.get(0)
    new Slip(list)

    list.addEventListener 'slip:beforeswipe', (e) -> e.preventDefault()

    list.addEventListener 'slip:beforewait', ((e) ->
      if $(e.target).hasClass("icon-reorder") then e.preventDefault()
    ), false

    list.addEventListener 'slip:beforereorder', ((e) ->
      if not $(e.target).hasClass("icon-reorder") then e.preventDefault()
    ), false

    list.addEventListener 'slip:reorder', ((e) =>
      e.target.parentNode.insertBefore(e.target, e.detail.insertBefore)
      @_update_input_value()
      return false
    ), false




