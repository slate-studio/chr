# -----------------------------------------------------------------------------
# Author: Alexander Kravets <alex@slatestudio.com>,
#         Slate Studio (http://www.slatestudio.com)
# -----------------------------------------------------------------------------
# VIEW TABS
# -----------------------------------------------------------------------------
# Example:
#
#   viewTabs:
#     editor: 'Page'
#     settings: 'Options'
#   formSchema:
#     editor:
#       type: 'group'
#       inputs:
#         ...
#     settings:
#       type: 'group'
#       inputs:
#         ...
# -----------------------------------------------------------------------------
@viewTabs =
  # PRIVATE ===================================================================
  _build_tabs: ->
    @$title.addClass "title-with-tabs"

    @_create_tabs()
    @_activate_tab(0)

  _create_tabs: ->
    @tabGroups = []
    groupsHash = {}

    for g in @form.groups
      groupsHash[g.klassName] = g

    @$tabs =$ "<aside class='header-tabs'></aside>"
    @$title.after @$tabs

    for tab_id, tab_title of @config.viewTabs
      @tabGroups.push(groupsHash[tab_id])
      @$tabs.append(@_create_button(tab_title))

  _create_button: (name) ->
    $tabButton =$ "<button>#{ name }</button>"
    $tabButton.on "click", (e) =>
      @_on_tab_click($(e.currentTarget))
    return $tabButton

  _on_tab_click: ($link) ->
    index = @$tabs.children().index($link)
    @_activate_tab(index)
    @$content.scrollTop(0)

  _activate_tab: (index) ->
    @$tabs.children().removeClass("active")
    @$tabs.find(":nth-child(#{ index + 1 })").addClass('active')

    for g in @tabGroups
      g.$el.hide()

    @tabGroups[index].$el.show()
