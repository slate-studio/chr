#= require jquery
#= require jquery_ujs
#= require chr

# ----------------------------------------------------------------------------------------
# TEST NOTES
# ----------------------------------------------------------------------------------------

## Module
# showNestedListsAside  - We don`t use it anymore? — Yes, we do, please add to tests.

## List
# disableNewItems:  true  tested
# showWithParent:   true  tested

## View
# disableDelete     - do not add delete button below the form  tested
# disableSave       - do not add save button in header         tested
# fullsizeView      — use fullsize layout in desktop mode      tested
# onViewShow        - on show callback
# defaultNewObject  - used to generate new form

## Rest-Array
# urlParams:        true  tested
# searchable:       true  tested

## Array
#   sortBy       — objects field name which is used for sorting, does not sort
#                  when parameter is not provided, default: nil
#   sortReverse  — reverse objects sorting (descending order), default: false
# reorderable             tested

# ----------------------------------------------------------------------------------------

$ ->
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

  chr.start('Test', config)




