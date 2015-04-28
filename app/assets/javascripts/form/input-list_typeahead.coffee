# -----------------------------------------------------------------------------
# Author: Alexander Kravets <alex@slatestudio.com>,
#         Slate Studio (http://www.slatestudio.com)
#
# Coding Guide:
#   https://github.com/thoughtbot/guides/tree/master/style/coffeescript
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# INPUT LIST TYPEAHEAD
# -----------------------------------------------------------------------------

@inputListTypeahead =

  # PRIVATE ===============================================

  _create_typeahead_el: (placeholder) ->
    # typeahead input for adding new items
    @typeaheadInput =$ "<input type='text' placeholder='#{ placeholder }' />"
    @$el.append @typeaheadInput


  _bind_typeahead: ->
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




