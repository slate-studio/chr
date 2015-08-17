  #-------------------------------------------------------------------------------------
  
  ## Config

  # disableNewItems:  true - do not show new item button in list header
  # showWithParent:   true - show list on a aside from parent
  # disableFormCache: true - do disable cache (desirable use in set with reorderable)
  # searchable:       true - add search button
  # reorderable:      true - permit reorder items
  # disableDelete:    true - do not add delete button below the form
  # disableSave:      true - do not add save button in header    
  # fullsizeView:     true - use fullsize layout in desktop mode
  # urlParams:        Article.sport_articles  - additional parameter to be included into request
  # sortReverse:      true - reverse objects sorting (descending order), default: false
  # pagination:       true - add this, if there are many objects (add extra test)

  # compoundModule:   true - add this, if module is compound (add extra test)
  # uploaderImage:    true - run tests, for checking uploader

  #-------------------------------------------------------------------------------------

require 'test_helper'
class ArticleFrontEndTest < ActionDispatch::IntegrationTest

  factory_name      = 'article'
  class_name        = Article
  list_of_modules   = ['articles']
  config            = {searchable: true, reorderable: true, pagination: true, uploaderImage: true}
  character_front_end(factory_name, class_name, list_of_modules, config)

end


