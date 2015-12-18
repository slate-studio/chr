# -----------------------------------------------------------------------------
# Author: Alexander Kravets <alex@slatestudio.com>,
#         Slate Studio (http://www.slatestudio.com)
# -----------------------------------------------------------------------------
# LIST ITEM
# -----------------------------------------------------------------------------
# config options:
#   onItemRender
#
# public methods:
#   render()
#   destroy()
#   position()
# -----------------------------------------------------------------------------
class @Item
  constructor: (@module, @path, @object, @config, @type) ->
    @$el =$ """<a class='item is-#{ @type }'
                  href='#{ @path }'
                  data-id='#{ @object._id }'
                  data-path='#{ @path }'>
               </a>"""

    if @type == 'folder'
      if !@config.showWithParent
        @$el.addClass 'folder-nested'

    @render()

  # PRIVATE ===================================================================

  _render_title: ->
    title  = @object.__title__ # title for @config.items
    title ?= @object[@config.itemTitleField]
    title ?= @object['_list_item_title']
    title ?= _firstNonEmptyValue(@object)
    title ?= "No Title"

    @$title =$ "<div class='item-title'>#{ title }</div>"
    @$el.append(@$title)

  _render_subtitle: ->
    subtitle = @object.__subtitle__ # subtitle for @config.items

    if @config.itemSubtitleField
      subtitle ?= @object[@config.itemSubtitleField]

    subtitle ?= @object['_list_item_subtitle']

    if subtitle
      @$subtitle =$ "<div class='item-subtitle'>#{ subtitle }</div>"
      @$el.append(@$subtitle)
      @$el.addClass 'has-subtitle'

  _render_thumbnail: ->
    imageUrl  = @config.itemThumbnail?(@object)
    imageUrl ?= @object[@config.itemThumbnail]
    imageUrl ?= @object['_list_item_thumbnail']

    if imageUrl
      # RAILS carrierwave fix, check if still required
      if not imageUrl.endsWith('_old_')
        @$thumbnail =$ "<div class='item-thumbnail'><img src='#{ imageUrl }' /></div>"
        @$el.append(@$thumbnail)
        @$el.addClass 'has-thumbnail'

  # PUBLIC ====================================================================

  render: ->
    @$el.html('').removeClass('has-subtitle has-thumbnail')

    @_render_title()
    @_render_subtitle()

    # if @type == 'folder'
    @$el.append $("<div class='icon-folder'>#{Icons.folder}</div>")

    if @type == 'object'
      @_render_thumbnail()

      if @config.arrayStore and @config.arrayStore.reorderable
        @$el.addClass('reorderable')
        @$el.append $("<div class='icon-reorder'>#{Icons.reorder}</div>")

    if @type == 'object'
      @config.onItemRender?(this)

  destroy: ->
    @$el.remove()

  position: ->
    positionFieldName = @config.arrayStore.sortBy
    parseFloat(@object[positionFieldName])
