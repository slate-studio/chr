# -----------------------------------------------------------------------------
# ITEM
# -----------------------------------------------------------------------------
class @Item
  _is_folder: ->
    # TODO: update this logic as it's not reliable
    if @object._title then true else false


  _render_title: ->
    title  = @object._title # nested list title predefined in config (or slug based)
    title ?= @object[@config.itemTitleField] # based on config
    title ?= _firstNonEmptyValue(@object) # auto-generated: first non empty value
    title ?= "No Title"
    title  = _stripHtml(title)

    @$title =$ "<div class='item-title'>#{title}</div>"
    @$el.append(@$title)
    @$el.attr  'data-title', title


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
      if imageUrl != '' and not imageUrl.endsWith('_old_') # NOTE: carrierwave fix, check if still required
        @$thumbnail =$ "<div class='item-thumbnail'><img src='#{imageUrl}' /></div>"
        @$el.append(@$thumbnail)
        @$el.addClass 'has-thumbnail'


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


  constructor: (@module, @path, @object, @config) ->
    @$el =$ """<a class='item' href='#{ @path }' data-id='#{ @object._id }' data-title=''></a>"""
    @$el.on 'click', (e) => @onClick(e)
    @render()


  onClick: (e) ->
    if @.$el.hasClass('active') then e.preventDefault() ; return

    window._skipHashchange = true
    location.hash = $(e.currentTarget).attr('href')

    title  = $(e.currentTarget).attr('data-title')
    id     = $(e.currentTarget).attr('data-id')
    crumbs = location.href.split('/')

    if @config.arrayStore and crumbs[crumbs.length - 2] == 'view'
      object = @config.arrayStore.get(id)

    if @config.objectStore
      object = @config.objectStore.get()

    if object
      return @module.showView(object, @config, title, true)

    @module.showNestedList(_last(crumbs), true)


  destroy: ->
    @$el.remove()


  position: ->
    positionFieldName = @config.arrayStore.sortBy
    parseFloat(@object[positionFieldName])





