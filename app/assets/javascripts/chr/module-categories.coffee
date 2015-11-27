# ------------------------------------------------------------------------------
# Author: Alexander Kravets <alex@slatestudio.com>,
#         Slate Studio (http://www.slatestudio.com)
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# MODULE CATEGORIES
# ------------------------------------------------------------------------------
# This is helper to implement UI for has many relations with an option to edit
# parent and child documents. E.g `BlogCategory` has many `BlogPost`s.
# ------------------------------------------------------------------------------
# USAGE EXAMPLE
# ------------------------------------------------------------------------------
# @postsConfig = ->
#   config =
#     title: "Categories"
#     menuTitle: "Posts"
#     arrayStore: new RailsArrayStore({
#       resource: "category"
#       path: "/admin/categories"
#       searchable:  true
#       orderBy: "_position"
#     })
#     items:
#       all_posts: postsListConfig()
#   new ModuleCategories(config, 'by_channel', postsListConfig)
# ------------------------------------------------------------------------------

# TODO: fix issue after cancel search button is clicked.

class @ModuleCategories
  constructor: (config, @scopeParam, @nestedListConfigMethod) ->
    config.onModuleInit = (@module) =>
      @module.moduleCategories = this
      @_initialize_module()

    config.onItemRender = (item) =>
      @_update_item_path(item)
      item.$el.on "click", (e) =>
        e.preventDefault()
        @_add_hidden_list(item)
        @_show_hidden_list(item)

    return config

  _initialize_module: ->
    @rootList = @module.rootList
    @nestedLists = @module.nestedLists
    moduleName = @module.name
    firstNestedListPath = _firstNonEmptyValue(@nestedLists).path

    @module.$el.addClass("module-categories")
    if chr.isDesktop()
      chr.$mainMenu
        .find(".menu-#{moduleName}")
        .attr("href", firstNestedListPath)

  _id: (item) ->
    item.object._id

  _slug: (item) ->
    id = @_id(item)
    "c_#{id}"

  _path: (item) ->
    slug = @_slug(item)
    "#{@rootList.path}/#{slug}"

  _title: (item) ->
    item.object.title

  _update_item_path: (item) ->
    path = @_path(item)
    paths = item.$el.attr("href") + ",#{path}"
    item.$el.data("path", paths)

  _hide_nested_lists: ->
    l.hide() for k, l of @nestedLists

  _show_hidden_list: (item) ->
    slug = @_slug(item)
    list = @nestedLists[slug]

    @_hide_nested_lists()

    @module.showList(slug)
    list.updateItems()
    chr.updateHash(list.path, true)

  _add_hidden_list: (item) ->
    slug = @_slug(item)
    if ! @nestedLists[slug]
      urlParams = {}
      urlParams[@scopeParam] = @_id(item)

      config = @nestedListConfigMethod()
      config.title = @_title(item)
      config.arrayStore.config.urlParams = urlParams

      @module.addNestedList(slug, config, @rootList)
