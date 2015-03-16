# -----------------------------------------------------------------------------
# INPUT LIST
# Allows to create/delete/reorder list items connected to dynamic or static
# collection. Value should be an array of objects.
#
# Dependencies:
#  - jquery.typeahead
#  - slip
# -----------------------------------------------------------------------------
class @InputList extends InputString
  _updateInputValue: ->
    ids = []
    @$items.children('li').each (i, el)->
      ids.push $(el).attr('data-id')
    value = ids.join(',')
    @$input.val(value)

  _removeItem: ($el) ->
    id = $el.attr('data-id')
    delete @objects[id]

    $el.parent().remove()
    @_updateInputValue()

  _addItem: (o) ->
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
    @_updateInputValue()

  _addItems: ->
    @reorderContainerClass = @config.klassName
    @objects = {}
    @$items  =$ "<ul class='#{ @reorderContainerClass }'></ul>"

    for o in @value
      @_addItem(o)

    @typeaheadInput.before @$items

  _addInput: ->
    # hidden input that stores ids
    # NOTE: we use __LIST__ prefix to identify ARRAY input type and
    #       process it's value while form submission.
    name = if @config.namePrefix then "#{@config.namePrefix}[__LIST__#{@config.target}]" else "[__LIST__#{@config.target}]"

    @$input =$ "<input type='hidden' name='#{ name }' value='' />"
    @$el.append @$input

    # NOTE: other options might be added here (static collection)
    if @config.typeahead
      # typeahead input for adding new items
      placeholder = @config.typeahead.placeholder
      @typeaheadInput =$ "<input type='text' placeholder='#{ placeholder }' />"
      @$el.append @typeaheadInput

    @_addItems()
    @_updateInputValue()

  #
  # PUBLIC
  #

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
        @_addItem(object)
        @typeaheadInput.typeahead('val', '')

    # events
    @$items.on 'click', '.action_remove', (e) =>
      e.preventDefault()
      if confirm('Are you sure?')
        @_removeItem($(e.currentTarget))

    # reorder
    list = @$items.get(0)
    new Slip(list)

    list.addEventListener 'slip:beforeswipe', (e) -> e.preventDefault()

    list.addEventListener 'slip:beforewait', ((e) ->
      if $(e.target).hasClass("icon-reorder") then e.preventDefault()
    ), false

    list.addEventListener 'slip:beforereorder', ((e) ->
      if not $(e.target).hasClass("icon-reorder") then e.preventDefault()
    ), false

    list.addEventListener 'slip:reorder', ((e) =>
      e.target.parentNode.insertBefore(e.target, e.detail.insertBefore)
      @_updateInputValue()
      return false
    ), false

    @config.onInitialize?(this)

  # TODO: add support
  updateValue: (@value) ->

  hash: (hash={}) ->
    hash[@config.klassName] = []
    ids                     = @$input.val().split(',')
    hash[@config.klassName].push(@objects[id]) for id in ids
    return hash

_chrFormInputs['list'] = InputList




