
# -----------------------------------------------------------------------------
# LIST CONFIG
# Methods for processing:
#   - @config.items
#   - @config.arrayStore
# -----------------------------------------------------------------------------

@listConfig =
  # PRIVATE ===============================================

  _add_item: (path, object, position, config, type) ->
    item = new @itemClass(@module, path, object, config, type)
    @items[object._id] = item
    @_update_item_position(item, position)


  _update_item_position: (item, position) ->
    # skip static items in the head of list
    position = @_config_items_count + position
    if position == 0
      @$items.prepend(item.$el)
    else
      @$items.append(item.$el.hide())
      $(@$items.children()[position - 1]).after(item.$el.show())


  _process_config_items: ->
    for slug, config of @config.items
      object =
        _id:      slug
        title:    config.title    ? slug.titleize()
        subtitle: config.subtitle ? ''

      item_type = 'nested_object'

      if config.items || config.arrayStore
        item_type = 'folder'
        @module.addNestedList(slug, config, this)

      config.itemTitleField    = 'title'
      config.itemSubtitleField = 'subtitle'

      @_add_item("#{ @path }/#{ slug }", object, 0, config, item_type)
      @_config_items_count += 1


  _bind_config_array_store: ->
    # item added
    @config.arrayStore.on 'object_added', (e, data) =>

      @_add_item("#{ @path }/view/#{ data.object._id }", data.object, data.position, @config, 'object')

    if @config.objects
      @config.arrayStore.addObjects(@config.objects)

    # item updated
    @config.arrayStore.on 'object_changed', (e, data) =>
      item = @items[data.object._id]
      if item then item.render() ; @_update_item_position(item, data.position)

    # item removed
    @config.arrayStore.on 'object_removed', (e, data) =>
      item = @items[data.object_id]
      if item then item.destroy() ; delete @items[data.object_id]

    # items loaded
    @config.arrayStore.on 'objects_added', (e, data) =>
      @hideSpinner()
      @_set_active_item()

    if @config.arrayStore.pagination
      @_bind_pagination()

    if @config.arrayStore.searchable
      @_bind_search()

    if @config.arrayStore.reorderable
      @_bind_reorder()




