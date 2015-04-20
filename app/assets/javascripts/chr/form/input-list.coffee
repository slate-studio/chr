# -----------------------------------------------------------------------------
# Author: Alexander Kravets <alex@slatestudio.com>,
#         Slate Studio (http://www.slatestudio.com)
#
# Coding Guide:
#   https://github.com/thoughtbot/guides/tree/master/style/coffeescript
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# INPUT LIST
# -----------------------------------------------------------------------------
# Allows to create/delete/reorder list items connected to dynamic or static
# collection. Value should be an array of objects.
#
# Dependencies:
#= require ./input-list_reorder
#
# -----------------------------------------------------------------------------

class @InputList extends InputString

  # PRIVATE ===============================================

  _add_input: ->
    # hidden input that stores ids, we use __LIST__ prefix to identify
    # ARRAY input type and process it's value while form submission.
    name = if @config.namePrefix then "#{ @config.namePrefix }[__LIST__#{ @config.target }]" else "[__LIST__#{ @config.target }]"

    @$input =$ "<input type='hidden' name='#{ name }' value='' />"
    @$el.append @$input

    # list holder for items
    @reorderContainerClass = @config.klassName
    @$items =$ "<ul class='#{ @reorderContainerClass }'></ul>"
    @$el.append @$items

    # other options might be added here (static collection)
    if @config.typeahead
      # typeahead input for adding new items
      placeholder = @config.typeahead.placeholder
      @typeaheadInput =$ "<input type='text' placeholder='#{ placeholder }' />"
      @$el.append @typeaheadInput

    @_render_items()
    @_update_input_value()


  _update_input_value: ->
    ids = []
    @$items.children('li').each (i, el) -> ids.push $(el).attr('data-id')

    # @TODO: we need a better separator here, comma is too generic
    #        it's used cause most cases list of IDs concidered to be here,
    #        we might make this a @config setting.
    value = ids.join(',')

    @$input.val(value)
    @$input.trigger('change')


  _remove_item: ($el) ->
    id = $el.attr('data-id')
    delete @objects[id]

    $el.parent().remove()
    @_update_input_value()


  _ordered_ids: ->
    ids = @$input.val().split(',')
    if ids[0] == '' then ids = []
    return ids


  _render_items: ->
    @$items.html('')
    @objects = {}

    for o in @value
      @_render_item(o)


  _render_item: (o) ->
    @_add_object(o)

    if @config.itemTemplate
      item = @config.itemTemplate(o)
    else
      item = o[@config.titleFieldName]

    listItem =$ """<li data-id='#{ o._id }'>
                     <span class='icon-reorder' data-container-class='#{ @reorderContainerClass }'></span>
                     #{ item }
                     <a href='#' class='action_remove'>Remove</a>
                   </li>"""
    @$items.append(listItem)
    @_update_input_value()


  _add_object: (o) ->
    @_normalize_object(o)
    @objects[o._id] = o


  _normalize_object: (o) ->
    o._id ?= o.id
    if ! o._id then console.log("::: list item is missing an 'id' or '_id' :::")


  # PUBLIC ================================================

  initialize: ->
    # typeahead
    if @config.typeahead
      limit = @config.typeahead.limit || 5
      dataSource = new Bloodhound
        datumTokenizer: Bloodhound.tokenizers.obj.whitespace(@config.titleFieldName)
        queryTokenizer: Bloodhound.tokenizers.whitespace
        remote:
          url:    @config.typeahead.url
          # exclude objects that are already in the list
          filter: (parsedResponse) =>
            data = []
            for o in parsedResponse
              @_normalize_object(o) ; if ! @objects[o._id] then data.push(o)
            return data
        limit:  limit

      dataSource.initialize()

      @typeaheadInput.typeahead({
        hint:       false
        highlight:  true
      }, {
        name:       @config.klassName
        displayKey: @config.titleFieldName
        source:     dataSource.ttAdapter()
      })

      @typeaheadInput.on 'typeahead:selected', (e, object, dataset) =>
        @_render_item(object)
        @typeaheadInput.typeahead('val', '')

    # remove
    @$items.on 'click', '.action_remove', (e) =>
      e.preventDefault()
      if confirm('Are you sure?') then @_remove_item($(e.currentTarget))

    @_bind_reorder()

    @config.onInitialize?(this)


  updateValue: (@value) ->
    @_render_items()


  hash: (hash={}) ->
    hash[@config.target] = @$input.val()
    ordered_objects = []

    for id in @_ordered_ids()
      ordered_objects.push(@objects[id])

    hash[@config.klassName] = ordered_objects
    return hash


include(InputList, inputListReorder)


chr.formInputs['list'] = InputList




