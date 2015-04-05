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
    # hidden input that stores ids
    # we use __LIST__ prefix to identify ARRAY input type and
    # process it's value while form submission.
    name = if @config.namePrefix then "#{@config.namePrefix}[__LIST__#{@config.target}]" else "[__LIST__#{@config.target}]"

    @$input =$ "<input type='hidden' name='#{ name }' value='' />"
    @$el.append @$input

    # other options might be added here (static collection)
    if @config.typeahead
      # typeahead input for adding new items
      placeholder = @config.typeahead.placeholder
      @typeaheadInput =$ "<input type='text' placeholder='#{ placeholder }' />"
      @$el.append @typeaheadInput

    @_add_items()
    @_update_input_value()


  _update_input_value: ->
    ids = []
    @$items.children('li').each (i, el)->
      ids.push $(el).attr('data-id')
    value = ids.join(',')
    @$input.val(value)


  _remove_item: ($el) ->
    id = $el.attr('data-id')
    delete @objects[id]

    $el.parent().remove()
    @_update_input_value()


  _add_item: (o) ->
    id = o['_id']

    @objects[id] = o

    if @config.itemTemplate
      item = @config.itemTemplate(o)
    else
      item = o[@config.titleFieldName]

    listItem =$ """<li data-id='#{ id }'>
                     <span class='icon-reorder' data-container-class='#{ @reorderContainerClass }'></span>
                     #{ item }
                     <a href='#' class='action_remove'>Remove</a>
                   </li>"""
    @$items.append listItem
    @_update_input_value()


  _add_items: ->
    @reorderContainerClass = @config.klassName
    @objects = {}
    @$items  =$ "<ul class='#{ @reorderContainerClass }'></ul>"

    for o in @value
      @_add_item(o)

    @typeaheadInput.before @$items


  # PUBLIC ================================================

  initialize: ->
    # typeahead
    if @config.typeahead
      limit = @config.typeahead.limit || 5
      dataSource = new Bloodhound
        datumTokenizer: Bloodhound.tokenizers.obj.whitespace(@config.titleFieldName)
        queryTokenizer: Bloodhound.tokenizers.whitespace
        remote: @config.typeahead.url
        limit:  limit

      dataSource.initialize()

      @typeaheadInput.typeahead({
        hint:       false
        highlight:  true
      }, {
        name:       @config.klassName,
        displayKey: @config.titleFieldName,
        source:     dataSource.ttAdapter()
      })

      @typeaheadInput.on 'typeahead:selected', (e, object, dataset) =>
        @_add_item(object)
        @typeaheadInput.typeahead('val', '')

    # remove
    @$items.on 'click', '.action_remove', (e) =>
      e.preventDefault()
      if confirm('Are you sure?') then @_remove_item($(e.currentTarget))

    @_bind_reorder()

    @config.onInitialize?(this)


  hash: (hash={}) ->
    hash[@config.klassName] = []
    ids                     = @$input.val().split(',')
    hash[@config.klassName].push(@objects[id]) for id in ids
    return hash


  updateValue: (@value) ->
    @$items.html('')
    @_add_item(o) for o in @value


include(InputList, inputListReorder)


chr.formInputs['list'] = InputList




