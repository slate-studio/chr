
# -----------------------------------------------------------------------------
# LIST CONFIG
# Methods for processing:
#   - @config.items
#   - @config.arrayStore
#   - @config.objectStore
# -----------------------------------------------------------------------------

@listConfig =
  # PRIVATE ===============================================

  _process_config_items: ->
    for slug, config of @config.items
      object = { _id: slug, _title: config.title ? slug.titleize() }

      # There might be some cases when we need this:
      #if config.objectStore
      #  $.extend(object, config.objectStore.get())

      if config.items or config.arrayStore
        @module.addNestedList(slug, config, this)

      @_add_item("#/#{ @path }/#{ slug }", object, 0, config)
      @configItemsCount += 1


  _bind_config_array_store: ->
    # item added
    @config.arrayStore.on 'object_added', (e, data) =>
      @_add_item("#/#{ @path }/view/#{ data.object._id }", data.object, data.position, @config)

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
      @_hide_spinner()
      @_set_active_item()

    if @config.arrayStore.pagination
      @_bind_pagination()

    if @config.arrayStore.searchable
      @_bind_search()

    if @config.arrayStore.reorderable
      @_bind_reorder()


  _bind_config_object_store: ->




