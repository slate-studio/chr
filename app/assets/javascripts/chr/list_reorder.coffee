# -----------------------------------------------------------------------------
# LIST REORDER
# -----------------------------------------------------------------------------
# Dependencies:
#= require vendor/slip
# -----------------------------------------------------------------------------
@listReorder =

  # PRIVATE ===================================================================

  _bind_reorder: ->
    items      = @items
    list       = @$items.get(0)
    arrayStore = @config.arrayStore

    config = arrayStore.reorderable

    # this is optimistic scenario when assumes that all positions are different
    _getObjectNewPosition = (el) ->
      $el =$ el

      nextObjectId = $el.next().attr('data-id')
      prevObjectId = $el.prev().attr('data-id')
      nextObjectPosition = 0
      prevObjectPosition = 0

      if prevObjectId
        prevObjectPosition = items[prevObjectId].position()

      if nextObjectId
        nextObjectPosition = items[nextObjectId].position()

      if arrayStore.sortReverse
        newPosition = nextObjectPosition + Math.abs(nextObjectPosition - prevObjectPosition) / 2.0
      else
        newPosition = prevObjectPosition + Math.abs(nextObjectPosition - prevObjectPosition) / 2.0

      return newPosition

    new Slip(list)

    list.addEventListener 'slip:beforeswipe', (e) -> e.preventDefault()

    list.addEventListener 'slip:beforewait', ((e) ->
      if $(e.target).hasClass("icon-reorder") then e.preventDefault()
    ), false

    list.addEventListener 'slip:beforereorder', ((e) ->
      if not $(e.target).hasClass("icon-reorder") then e.preventDefault()
    ), false

    list.addEventListener 'slip:reorder', ((e) =>
      # when `e.detail.insertBefore` is null, item put to the end of the list.
      e.target.parentNode.insertBefore(e.target, e.detail.insertBefore)

      objectPositionValue = _getObjectNewPosition(e.target)
      objectId = $(e.target).attr('data-id')
      value = {}
      value["[#{arrayStore.sortBy}]"] = "#{ objectPositionValue }"

      arrayStore.update objectId, value,
        # error handling
        onSuccess: (object) => ;
        onError: (errors) => ;

      return false
    ), false

    $(list).addClass 'reorderable'
