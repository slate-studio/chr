# -----------------------------------------------------------------------------
# Author: Alexander Kravets <alex@slatestudio.com>,
#         Slate Studio (http://www.slatestudio.com)
#
# Coding Guide:
#   https://github.com/thoughtbot/guides/tree/master/style/coffeescript
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# INPUT HTML
# -----------------------------------------------------------------------------
#
# Usage: onInitialize: (form, group) -> new ExpandableGroup(form, group, 'Details')
#
# -----------------------------------------------------------------------------

@_expandableGroupStateCache = {}
class @ExpandableGroup
  constructor: (@form, @group, name) ->
    @$expander =$ """<a href='#' class='group-edit hidden'>#{ name }</a>"""
    @group.$el.before @$expander

    @_restore_expander_from_cache()

    @$expander.on 'click', (e) =>
      @_toggle_expander()
      e.preventDefault()


  # PRIVATE ===============================================

  _restore_expander_from_cache: ->
    if _expandableGroupStateCache.__hash
      if _expandableGroupStateCache.__hash == window.location.hash
        if _expandableGroupStateCache[@_group_id()]
          @$expander.removeClass 'hidden'
      if _expandableGroupStateCache.__hash.endsWith 'new'
        @$expander.removeClass 'hidden'


  _toggle_expander: ->
    @$expander.toggleClass('hidden')
    @_cache_expander_state()


  _cache_expander_state: ->
    _expandableGroupStateCache.__hash = window.location.hash
    _expandableGroupStateCache[@_group_id()] = @group.$el.is(':visible')


  _group_id: ->
    groupIndex = $('form').find(".group.#{@group.klassName}").index(@group.$el)
    return "#{ @group.klassName }-#{ groupIndex }"





