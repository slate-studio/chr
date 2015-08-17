#---------------------------------------------------------------------------------
## List of functions

# show_item(factory_name, list_of_modules)
# chage_title(factory_name, class_name, list_of_modules)
# add_item(factory_name, class_name, list_of_modules)
# delete_item(factory_name, class_name, list_of_modules)
# open_item_and_close(factory_name, list_of_modules)
# search(factory_name, list_of_modules)
# search_and_close(factory_name, class_name, list_of_modules)
# reorder(factory_name, class_name, list_of_modules)
# show_with_parent(factory_name, list_of_modules)
# disable_new_item(factory_name, list_of_modules)
# disable_delete(factory_name, list_of_modules)
# disable_save(factory_name, list_of_modules)
# fullsize_view(factory_name, list_of_modules)
# add_class_active(factory_name, list_of_modules)
# pagination(factory_name, class_name, list_of_modules)
# pagination_and_reorder(factory_name, class_name, list_of_modules)
# click_back(factory_name, list_of_modules)
# chage_position_to_end_and_check_pagination(factory_name, class_name, list_of_modules)
# chage_position_to_begin_and_check_pagination(factory_name, class_name, list_of_modules)
# chage_position_to_middle_and_check_pagination(factory_name, class_name, list_of_modules)
# create_first_item_and_check_pagination(factory_name, class_name, list_of_modules)
# create_last_item_on_page_and_check_pagination(factory_name, class_name, list_of_modules)
# urlParams(factory_name, class_name, list_of_modules, config)
# remove_from_scope(factory_name, class_name, list_of_modules, config)
# sortReverse_by_position(factory_name, class_name, list_of_modules)
# add_image(factory_name, list_of_modules)
# remove_image(factory_name, list_of_modules)


#---------------------------------------------------------------------------------

Dir[Rails.root.join("../support/**/*.rb")].each{ |f| require f }
module CharacterFrontEnd
  include CharacterListTest
  include CharacterViewTest
  include CharacterSearchTest
  include CharacterReorderTest
  include CharacterPaginationTest
  include CharacterRestArrayTest
  include CharacterArrayTest
  include CharacterUploaderTest

  def character_front_end(factory_name, class_name, list_of_modules, config)

    show_item(factory_name, list_of_modules)
    open_item_and_close(factory_name, list_of_modules)
    add_class_active(factory_name, list_of_modules)
    
    if config[:disableNewItems]
      disable_new_item(factory_name, list_of_modules)
    else
      if config[:pagination]
        create_first_item_and_check_pagination(factory_name, class_name, list_of_modules)
        create_last_item_on_page_and_check_pagination(factory_name, class_name, list_of_modules)
      end
      add_item(factory_name, class_name, list_of_modules)
    end
    
    if config[:showWithParent]
      show_with_parent(factory_name, list_of_modules)
    end

    if config[:searchable]
      search(factory_name, list_of_modules)
      search_and_close(factory_name, class_name, list_of_modules)
    end

    if config[:reorderable]
      reorder(factory_name, class_name, list_of_modules)
      if config[:pagination]
        pagination_and_reorder(factory_name, class_name, list_of_modules)
        reorder_to_begin_of_list(factory_name, class_name, list_of_modules)
      end
    end

    if config[:disableDelete]
      disable_delete(factory_name, list_of_modules)
    else
      delete_item(factory_name, class_name, list_of_modules)
    end

    if config[:disableSave]
      disable_save(factory_name, list_of_modules)
    else
      if config[:pagination]
        chage_position_to_end_and_check_pagination(factory_name, class_name, list_of_modules)
        chage_position_to_begin_and_check_pagination(factory_name, class_name, list_of_modules)
        chage_position_to_middle_and_check_pagination(factory_name, class_name, list_of_modules)
      end
      chage_title(factory_name, class_name, list_of_modules)
    end
      
    if config[:fullsizeView]  
      fullsize_view(factory_name, list_of_modules)
    end

    if config[:compoundModule]
      click_back(factory_name, list_of_modules)
    end
      
    if config[:pagination]
      pagination(factory_name, class_name, list_of_modules)
    end

    if config[:urlParams]
      urlParams(factory_name, class_name, list_of_modules, config)
      remove_from_scope(factory_name, class_name, list_of_modules, config)
    end

    if config[:sortReverse]
      #TODO -> Double check, for correct work with reorderable and pagination
      sortReverse_by_position(factory_name, class_name, list_of_modules)
    end

    if config[:uploaderImage]
      add_image(factory_name, list_of_modules)
      remove_image(factory_name, list_of_modules)
    end

  end 

      # save_and_open_screenshot

  protected

    def get_path_from_modules_list(list_of_modules)
      @path = ''
      list_of_modules.each do |module_name|
        @path += '/' + module_name
      end 
    end


    def show_form_of_item(list_of_modules, item_id)
      get_path_from_modules_list(list_of_modules)
      visit("/admin##{@path}/view/#{item_id}")
      wait_for_ajax
    end


    def select_last_module_from_list(list_of_modules)
      path = ''
      list_of_modules.each do |module_name|
        path += '/' + module_name
        find("a[href='##{path}']").click
        wait_for_ajax
      end
    end


    def create_n_objects(count, factory_name)
      @instances_of_class = []
      n = 0
      count.times do 
      @instances_of_class[n] = FactoryGirl.create(factory_name)
      n += 1
      end
    end


    def create_per_page_plus_n_objects(n, factory_name)
      y                        =  current_window.size[1]
      @items_per_page          = ((y+50)/60)*2
      @loaded_items            = @items_per_page
      create_n_objects(@items_per_page+n, factory_name)
      @first_item              = @instances_of_class.first
      @last_item               = @instances_of_class.last
      @last_item_on_first_page = @instances_of_class[@items_per_page-1]
      @middle_item             = @instances_of_class[@items_per_page/2]
      @before_middle_item      = @instances_of_class[(@items_per_page/2)-1]
    end


    def scoll_to_bottom
      page.execute_script(%Q{$("div.items").prop("scrollTop", 10000000).trigger('scroll')})
    end


    def drag_item(from, to)
      source = find("a[data-id='#{from.id}']").find("div.icon-reorder")
      target = find("a[data-id='#{to.id}']").find("div.icon-reorder")
      source.drag_to(target)
      wait_for_ajax
    end


    def upload_test_image_and_save
      page.attach_file('[image]', Rails.root + '../files/test.jpg')
      find_link('Save').click
      wait_for_ajax
    end

end