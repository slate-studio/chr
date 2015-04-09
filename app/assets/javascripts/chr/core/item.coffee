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
# public methods:
#   render()
#   destroy()
#   position()
#
# -----------------------------------------------------------------------------
class @Item
  constructor: (@module, @path, @object, @config) ->
    @$el =$ """<a class='item' href='#{ @path }' data-id='#{ @object._id }' data-title=''></a>"""
    @render()


  # PRIVATE ===============================================

  _is_folder: ->
    # update this logic as it's not reliable
    if @object._title then true else false


  _render_title: ->
    # nested list title predefined in config (or slug based)
    title  = @object._title
    # based on config
    title ?= @object[@config.itemTitleField]
    # auto-generated: first non empty value
    title ?= _firstNonEmptyValue(@object)
    title ?= "No Title"
    title  = title.plainText()

    @$title =$ "<div class='item-title'>#{ title }</div>"
    @$el.append(@$title)
    @$el.attr('data-title', title)


  _render_subtitle: ->
    if @config.itemSubtitleField
      subtitle   = @object[@config.itemSubtitleField]
      if subtitle != ''
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
    @$el.html('').removeClass('item-folder has-subtitle has-thumbnail')
    @_render_title()

    if @_is_folder()
      @$el.addClass('item-folder')
      @$el.append $("<div class='icon-folder'></div>")
    else
      @_render_subtitle()
      @_render_thumbnail()

      if @config.arrayStore and @config.arrayStore.reorderable
        @$el.addClass('reorderable')
        @$el.append $("<div class='icon-reorder'></div>")


  destroy: ->
    @$el.remove()


  position: ->
    positionFieldName = @config.arrayStore.sortBy
    parseFloat(@object[positionFieldName])




