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
    @$el.on 'click', (e) => @_click(e)
    @render()


  # PRIVATE ===============================================

  _is_folder: ->
    # update this logic as it's not reliable
    if @object._title then true else false


  _render_title: ->
    title  = @object._title # nested list title predefined in config (or slug based)
    title ?= @object[@config.itemTitleField] # based on config
    title ?= _firstNonEmptyValue(@object) # auto-generated: first non empty value
    title ?= "No Title"
    title  = title.plainText()

    @$title =$ "<div class='item-title'>#{ title }</div>"
    @$el.append(@$title)
    @$el.attr('data-title', title)


  _render_subtitle: ->
    if @config.itemSubtitleField
      subtitle   = @object[@config.itemSubtitleField]
      if subtitle != ''
        @$subtitle =$ "<div class='item-subtitle'>#{subtitle}</div>"
        @$el.append(@$subtitle)
        @$el.addClass 'has-subtitle'


  _render_thumbnail: ->
    if @config.itemThumbnail
      imageUrl = @config.itemThumbnail(@object)
      # carrierwave fix, check if still required
      if imageUrl != '' and not imageUrl.endsWith('_old_')
        @$thumbnail =$ "<div class='item-thumbnail'><img src='#{imageUrl}' /></div>"
        @$el.append(@$thumbnail)
        @$el.addClass 'has-thumbnail'


  # EVENTS ================================================

  _click: (e) ->
    if @.$el.hasClass('active') then e.preventDefault() ; return

    hash   = $(e.currentTarget).attr('href')
    crumbs = hash.split('/')
    title  = $(e.currentTarget).attr('data-title')
    id     = $(e.currentTarget).attr('data-id')

    chr.updateHash(hash, true)

    # show view for a arrayStore item
    if crumbs[crumbs.length - 2] == 'view'
      return @module.showViewByObjectId(id, @config, title)
    # show objectStore item view
    if @config.objectStore
      return @module.showViewByObjectId('', @config, title)
    # show nested list
    @module.showNestedList(_last(crumbs))


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




