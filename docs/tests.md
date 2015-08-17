## Running Tests

    rake test

#### Covered configs:

  # disableNewItems:   - do not show new item button in list header
  # showWithParent:    - show list on a aside from parent
  # disableFormCache:  - do disable cache
  # searchable:        - add search button
  # reorderable:       - permit reorder items
  # disableDelete:     - do not add delete button below the form
  # disableSave:       - do not add save button in header    
  # fullsizeView:      - use fullsize layout in desktop mode
  # urlParams:        Article.sport_articles  - additional parameter to be included into request
  # sortReverse:       - reverse objects sorting (descending order), default: false
  # pagination:        - add this, if there are many objects (add extra test)

  # uploaderImage:     - run tests, for checking uploader


#### Tests structure:

`test/integration/..` - Each file it's presentation of Module with different config, for test all functionallity
`test/support/character_front_end` - Main module with logic and helper methods, depending of config running appropriate set of tests.

**Modules with tests:**

    test/support/chr/...
    test/support/stores/...


#### Tests functions:

`show_item(factory_name, list_of_modules)`  Generate module, item and item_form
`chage_title(factory_name, class_name, list_of_modules)` Change fileds of items, also changing Model
`add_item(factory_name, class_name, list_of_modules)`  Create new object
`delete_item(factory_name, class_name, list_of_modules)` Delete object
`open_item_and_close(factory_name, list_of_modules)` Render item_form and close it
`search(factory_name, list_of_modules)` Generate search request, and check result
`search_and_close(factory_name, class_name, list_of_modules)` Generate search result, and reset it (check, that all items visible again)
`reorder(factory_name, class_name, list_of_modules)` Reorder objects by drag and drop (check that _position change, and rendering correct)
`show_with_parent(factory_name, list_of_modules)` Open item with showWithParent: true, check, that there are items and parent render on one page
`disable_new_item(factory_name, list_of_modules)` Render list without button "+"
`disable_delete(factory_name, list_of_modules)` Render View without button "delete"
`disable_save(factory_name, list_of_modules)` Render View without button "save"
`fullsize_view(factory_name, list_of_modules)` Render View with fullsizeView: true
`add_class_active(factory_name, list_of_modules)` Checking, that class active adding correctly.
`pagination(factory_name, class_name, list_of_modules)` Render list with many items, and scrolling to the buttom (checking for coreect download new pages)
`pagination_and_reorder(factory_name, class_name, list_of_modules)` Render list with many items, scrolling and reorder item on each page
`click_back(factory_name, list_of_modules)` Render last one of compound modules, click button "back"
**Checking Pagination:**

    chage_position_to_end_and_check_pagination(factory_name, class_name, list_of_modules
    chage_position_to_begin_and_check_pagination(factory_name, class_name, list_of_modules)
    chage_position_to_middle_and_check_pagination(factory_name, class_name, list_of_modules)
    create_first_item_and_check_pagination(factory_name, class_name, list_of_modules)
    create_last_item_on_page_and_check_pagination(factory_name, class_name, list_of_modules)

`urlParams(factory_name, class_name, list_of_modules, config)` Checking, that in generated list only items from scope (urlParams:true)
`remove_from_scope(factory_name, class_name, list_of_modules, config)` Remove item from scope (urlParams:true)
`sortReverse_by_position(factory_name, class_name, list_of_modules)` Checking, that list render in reverse order
`add_image(factory_name, list_of_modules)` Upload image
`remove_image(factory_name, list_of_modules)` Remove image
