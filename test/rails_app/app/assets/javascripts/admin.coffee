#= require jquery
#= require jquery_ujs
#= require chr
    
          ## Module
          # showNestedListsAside  - We don`t use it anymore?
         
          ## List
          # disableNewItems:  true  tested
          # showWithParent:   true  tested
          # disableFormCache: true  tested

          ## View
          # disableDelete     - do not add delete button below the form  tested
          # disableSave       - do not add save button in header         tested
          # fullsizeView      — use fullsize layout in desktop mode      tested
          # onViewShow        - on show callback
          # defaultNewObject  - used to generate new form

          ## Rest-Array
          # urlParams:         true tested
          # searchable:       true  tested

          ## Array
          #   sortBy       — objects field name which is used for sorting, does not sort
          #                  when parameter is not provided, default: nil
          #   sortReverse  — reverse objects sorting (descending order), default: false
          # reorderable             tested


$ ->
  $.get '/admin/bootstrap.json', (response) ->
    config =
      modules:
        fullsize_articles:
          fullsizeView: true

          arrayStore: new RailsArrayStore({
            resource:    'article'
            path:        '/admin/articles'
          })
          

          formSchema:
            title: { type: 'string' }
            description:  { type: 'text'   }
            body_html:    { type: 'text'   }

        restricted_articles:
          
          disableNewItems: true
          disableDelete: true
          disableSave: true

          arrayStore: new RailsArrayStore({
            resource:    'article'
            path:        '/admin/articles'
          })
          

          formSchema:
            title: { type: 'string' }
            description:  { type: 'text'   }
            body_html:    { type: 'text'   }
        
       
        articles:
          
          disableFormCache: true
          arrayStore: new RailsArrayStore({
            resource:    'article'
            path:        '/admin/articles'
            searchable: true
            reorderable: { positionFieldName: '_position' }
          })
          

          formSchema:
            title: { type: 'string' }
            description:  { type: 'text'   }
            _position:    { type: 'float'  }
            body_html:    { type: 'text'   }
            image:        { type: 'image', label: 'Image <small>(600x375)</small>', thumbnail: (o) -> o.image.regular_2x.url }


        magazine:
          title: 'Magazine'
          items:
            pages:
              title: 'Pages'
              showWithParent:   true
              disableFormCache: true
              items:
                articles:

                  arrayStore: new RailsArrayStore({
                    resource:    'article'
                    path:        '/admin/articles'
                    sortBy:      '_position'
                    sortReverse: true
                    searchable: true
                  })
                  

                  formSchema:
                    title: { type: 'string' }
                    description:  { type: 'text'   }
                    _position:    { type: 'float'  }
                    body_html:    { type: 'text'   }

        sport_articles:
          
          disableFormCache: true
          arrayStore: new RailsArrayStore({
            resource:    'article'
            path:        '/admin/articles'
            urlParams:   { sport_articles: true }
            searchable: true
            reorderable: { positionFieldName: '_position' }
          })
          

          formSchema:
            title: { type: 'string' }
            description:  { type: 'text'   }
            _position:    { type: 'float'  }
            body_html:    { type: 'text'   }


    $('body').removeClass('loading')
    chr.start(config)

    # append signout button to the end of sidebar menu
    $('a[data-method=delete]').appendTo(".sidebar .menu").show()