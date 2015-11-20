# -----------------------------------------------------------------------------
# Author: Alexander Kravets <alex@slatestudio.com>,
#         Slate Studio (http://www.slatestudio.com)
#
# Coding Guide:
#   https://github.com/thoughtbot/guides/tree/master/style/coffeescript
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# LIST
# -----------------------------------------------------------------------------
#
# Configuration options:
#   title              - list title
#   subtitle           - list subtitle
#   itemClass          - item class to be used instead of default one
#   itemTitleField     - object attributes name for list item title
#   itemSubtitleField  - object attributes name for list item subtitle
#   disableNewItems    - do not show new item button in list header
#   disableUpdateItems - do not update list items
#   onListInit         - callback on list is initialized
#   onListShow         - callback on list is shown
#   objects            - objects array to be added to the store on start
#   showWithParent     - show list on a aside from parent
#
# Public methods:
#   showSpinner()
#   hideSpinner()
#   hide()        - hide list
#   show()        - show list
#   updateItems() - update list items (sync through store with backend)
#   isVisible()   - check if list is visible
#
# Dependencies:
#= require ./list_config
#= require ./list_pagination
#= require ./list_reorder
#= require ./list_search
#
# -----------------------------------------------------------------------------

class @List
  constructor: (@module, @path, @name, @config, @parentList) ->
    @items     = {}
    @title     = @config.title      ? @name.titleize()
    @itemClass = @config.itemClass  ? Item

    @_config_items_count = 0

    @showWithParent = @config.showWithParent ? false

    @$el =$ "<div class='list #{ @name }' style='display:none;'>"
    @module.$el.append @$el

    if @showWithParent
      @$el.addClass('list-aside')

    # items
    @$items =$ "<div class='items'>"
    @$el.append @$items

    # header
    @$header =$ "<header class='header'></header>"
    @$el.append @$header

    # back
    @$backBtn =$ "<a href='#/' class='back'>#{ Icons.close }</a>"
    if @parentList
      @$backBtn.attr 'href', @parentList.path

    @$header.prepend @$backBtn

    # spinner & title
    @$header.append "<div class='spinner'></div>"
    @$header.append "<span class='title'>#{ @title }</span>"

    # new item
    if not @config.disableNewItems and @config.formSchema
      @$newBtn =$ "<a href='#{ @path }/new' class='new'>#{Icons.add}</a>"
      @$header.append @$newBtn

    if @config.items       then @_process_config_items()
    if @config.arrayStore  then @_bind_config_array_store()

    @_bind_hashchange()

    @config.onListInit?(@)


  # PRIVATE ===============================================

  _bind_hashchange: ->
    $(chr).on 'hashchange', => @_set_active_item()


  _set_active_item: ->
    hash = window.location.hash
    if hash.startsWith "#/#{ @module.name }"
      for a in @$items.children()
        itemPath = $(a).attr('href')
        if itemPath && hash.startsWith(itemPath)
          return $(a).addClass('active')


  # PUBLIC ================================================

  showSpinner: ->
    @$el.addClass('show-spinner')


  hideSpinner: ->
    @$el.removeClass('show-spinner')


  hide: ->
    @$el.hide()


  show: (callback) ->
    @$el.show 0, =>
      @config.onListShow?(@)
      callback?()


  updateItems: ->
    if not @config.disableUpdateItems
      if @config.arrayStore
        @showSpinner()
        @$items.scrollTop(0)
        @config.arrayStore.reset()


include(List, listConfig)
include(List, listPagination)
include(List, listReorder)
include(List, listSearch)




