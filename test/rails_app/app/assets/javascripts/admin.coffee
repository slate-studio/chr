#= require jquery
#= require jquery_ujs

#= require chr

@getConfig = (data) ->
  modules =
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
        image:        { type: 'image', label: 'Image <small>(600x375)</small>', thumbnail: (o) -> o.image.thumbnail_2x.url }


    magazine:
      title: 'Magazine'
      items:
        pages:
          title: 'Pages'
          showWithParent: true
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


    # loft: new Loft()
    # settings:
    #   items:
    #     admins:    new AntsAdminUsers()
    #     redirects: new AntsRedirects()

  return { modules: modules }

$ ->
  $.get '/admin/bootstrap.json', (response) ->
    config = getConfig(response)

    chr.start('test_chr', config)
    # new AntsProfile()
