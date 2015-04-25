# -----------------------------------------------------------------------------
# Author: Alexander Kravets <alex@slatestudio.com>,
#         Slate Studio (http://www.slatestudio.com)
#
# Coding Guide:
#   https://github.com/thoughtbot/guides/tree/master/style/coffeescript
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# LIST ITEM
# -----------------------------------------------------------------------------
#
# config options:
#   onItemRender
#
# public methods:
#   render()
#   destroy()
#   position()
#
# -----------------------------------------------------------------------------
class @Item
  constructor: (@module, @path, @object, @config, @type) ->
    @$el =$ """<a class='item is-#{ @type }' href='#{ @path }' data-id='#{ @object._id }'></a>"""
    @render()


  # PRIVATE ===============================================

  _render_title: ->
    title  = @object.__title__ # title for @config.items
    title ?= @object[@config.itemTitleField]
    title ?= _firstNonEmptyValue(@object)
    title ?= "No Title"
    title  = title.plainText()

    @$title =$ "<div class='item-title'>#{ title }</div>"
    @$el.append(@$title)


  _render_subtitle: ->
    subtitle = @object.__subtitle__ # subtitle for @config.items

    if @config.itemSubtitleField
      subtitle ?= @object[@config.itemSubtitleField]

    if subtitle
      @$subtitle =$ "<div class='item-subtitle'>#{ subtitle }</div>"
      @$el.append(@$subtitle)
      @$el.addClass 'has-subtitle'


  _render_thumbnail: ->
    if @config.itemThumbnail
      imageUrl = @config.itemThumbnail?(@object) ? @object[@config.itemThumbnail]

      # RAILS carrierwave fix, check if still required
      if imageUrl != '' and not imageUrl.endsWith('_old_')
        @$thumbnail =$ "<div class='item-thumbnail'><img src='#{ imageUrl }' /></div>"
        @$el.append(@$thumbnail)
        @$el.addClass 'has-thumbnail'


  # PUBLIC ================================================

  render: ->
    @$el.html('').removeClass('has-subtitle has-thumbnail')

    @_render_title()
    @_render_subtitle()

    if @type == 'folder'
      @$el.append $("<div class='icon-folder'></div>")

    if @type == 'object'
      @_render_thumbnail()

      if @config.arrayStore and @config.arrayStore.reorderable
        @$el.addClass('reorderable')
        @$el.append $("<div class='icon-reorder'></div>")

    @config.onItemRender?(this)


  destroy: ->
    @$el.remove()


  position: ->
    positionFieldName = @config.arrayStore.sortBy
    parseFloat(@object[positionFieldName])




