
# -----------------------------------------------------------------------------
# LIST CONFIG
# Methods for processing:
#   - @config.items
#   - @config.arrayStore
# -----------------------------------------------------------------------------

@listConfig =
  # PRIVATE ===============================================

  _process_config_items: ->
    @_config_items_count = 0
    for slug, config of @config.items
      object = { _id: slug, _title: config.title ? slug.titleize() }

      if config.items or config.arrayStore
        @module.addNestedList(slug, config, this)

      @_add_item("#{ @path }/#{ slug }", object, 0, config)
      @_config_items_count += 1


  _bind_config_array_store: ->
    # item added
    @config.arrayStore.on 'object_added', (e, data) =>
      @_add_item("#{ @path }/view/#{ data.object._id }", data.object, data.position, @config)

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




