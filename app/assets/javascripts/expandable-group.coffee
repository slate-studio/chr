# -----------------------------------------------------------------------------
# Author: Alexander Kravets <alex@slatestudio.com>,
#         Slate Studio (http://www.slatestudio.com)
#
# Coding Guide:
#   https://github.com/thoughtbot/guides/tree/master/style/coffeescript
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# EXPANDABLE GROUP
# -----------------------------------------------------------------------------
#
# Usage: onInitialize: (form, group) -> new ExpandableGroup(form, group, 'Details')
#
# -----------------------------------------------------------------------------

#@_expandableGroupStateCache = {}

class @ExpandableGroup
  constructor: (@form, @group, name) ->
    @$expander =$ """<a href='#' class='group-edit hidden'>#{ name }</a>"""
    @group.$el.before @$expander

    @$expander.on 'click', (e) =>
      @$expander.toggleClass('hidden')
      e.preventDefault()




