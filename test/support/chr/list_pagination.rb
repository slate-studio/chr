module CharacterPaginationTest

  def pagination(factory_name, class_name, list_of_modules)
    test 'Pagination' do
      create_per_page_plus_n_objects(50, factory_name)
      visit('/admin')
      wait_for_ajax
      # Select Module
      select_last_module_from_list(list_of_modules)
      while @loaded_items < class_name.count do
        assert page.has_css?('div.item-title', count: @loaded_items)
        scoll_to_bottom
        wait_for_ajax
        @loaded_items += @items_per_page
      end
      assert page.has_css?('div.item-title', count: class_name.count)
    end
  end


  def click_back(factory_name, list_of_modules)
    test 'Open last module in Hash and click back' do
      instance_of_class = FactoryGirl.create(factory_name)
      visit('/admin')
      wait_for_ajax
      # Select Module
      select_last_module_from_list(list_of_modules)
      list_of_modules -= [list_of_modules.last]
      get_path_from_modules_list(list_of_modules)
      find("a[href='##{@path}'].back", :text => 'Close').click
      wait_for_ajax
      assert_not page.has_css?("a[data-id='#{instance_of_class.id}']")
    end
  end


  def pagination_and_reorder(factory_name, class_name, list_of_modules)
    test 'pagination_and_reorder' do
      create_per_page_plus_n_objects(5, factory_name)
      visit('/admin')
      wait_for_ajax
      select_last_module_from_list(list_of_modules)
      while @loaded_items < class_name.count do
        assert page.has_css?('div.item-title', count: @loaded_items)
        scoll_to_bottom
        wait_for_ajax
        drag_item(@instances_of_class[@loaded_items-5], @instances_of_class[@loaded_items-4])
        @loaded_items += @items_per_page
      end
      assert page.has_css?('div.item-title', count: class_name.count)
    end
  end

 
  def chage_position_to_end_and_check_pagination(factory_name, class_name, list_of_modules)
    # If Module without disableFormCache need add reload page after "save"
    test 'Change Position to the End and Check Pagination' do
      create_per_page_plus_n_objects(2, factory_name)      
      show_form_of_item(list_of_modules, @first_item.id)
      find('label.input-_position input').set(@last_item._position + 5)
      find_link('Save').click
      sleep(1.0)
      assert page.has_css?('div.item-title', count: @loaded_items)
      assert_not page.has_css?("a[data-id='#{@first_item.id}']")
      scoll_to_bottom
      assert page.has_css?('div.item-title', count: class_name.count)
    end
  end


  def chage_position_to_middle_and_check_pagination(factory_name, class_name, list_of_modules)
    # If Module without disableFormCache need add reload page after "save"
    # Maybe not necessary
    test 'Change Position to the Middle and Check Pagination' do
      create_per_page_plus_n_objects(2, factory_name)
      show_form_of_item(list_of_modules, @first_item.id)
      find('label.input-_position input').set(@middle_item._position-1)
      find_link('Save').click
      sleep(1.0)
      assert page.has_css?('div.item-title', count: @loaded_items)
      title_middle_item = find("a[data-id='#{@first_item.id}']+a").text
      title_moved_item = find("a[data-id='#{@before_middle_item.id}']+a").text
      scoll_to_bottom
      assert page.has_css?('div.item-title', count: class_name.count)
      assert_equal @first_item.title, title_moved_item
      assert_equal @middle_item.title, title_middle_item
    end
  end


  def chage_position_to_begin_and_check_pagination(factory_name, class_name, list_of_modules)
    test 'Change Position to Begin and Check Pagination' do
      create_per_page_plus_n_objects(2, factory_name)      
      show_form_of_item(list_of_modules, @last_item.id)
      assert_not page.has_css?("a[data-id='#{@last_item.id}']")
      find('label.input-_position input').set(@first_item._position - 5)
      find_link('Save').click
      # Reload page
      visit('/admin')
      select_last_module_from_list(list_of_modules)
      assert page.has_css?('div.item-title', count: @loaded_items)
      assert page.has_css?("a[data-id='#{@last_item.id}']")
      assert_not page.has_css?("a[data-id='#{@last_item_on_first_page.id}']")
      scoll_to_bottom
      assert page.has_css?('div.item-title', count: class_name.count)
    end
  end


  def create_first_item_and_check_pagination(factory_name, class_name, list_of_modules)
    test 'Create First Item and Check Pagination' do
      create_per_page_plus_n_objects(2, factory_name)      
      visit('/admin')
      wait_for_ajax
      select_last_module_from_list(list_of_modules)
      # Click "+" 
      get_path_from_modules_list(list_of_modules)
      find("a[href='##{@path}/new']").click
      find('label.input-title input').set("10 ways to lose weight")
      find('label.input-_position input').set(@first_item._position - 5)
      find_link('Save').click
      # Reload page
      visit('/admin')
      select_last_module_from_list(list_of_modules)

      assert page.has_css?('div.item-title', count: @loaded_items)
      assert page.has_content?('10 ways to lose weight')
      assert_not page.has_css?("a[data-id='#{@last_item_on_first_page.id}']")
      scoll_to_bottom
      assert page.has_css?('div.item-title', count: class_name.count)
      assert page.has_css?("a[data-id='#{@last_item_on_first_page.id}']")
    end
  end


  def create_last_item_on_page_and_check_pagination(factory_name, class_name, list_of_modules)
    test 'Create Last Item to Page and Check Pagination' do
      create_per_page_plus_n_objects(2, factory_name)      
      visit('/admin')
      wait_for_ajax
      select_last_module_from_list(list_of_modules)
      # Click "+" 
      get_path_from_modules_list(list_of_modules)
      find("a[href='##{@path}/new']").click
      find('label.input-title input').set("10 ways to lose weight")
      find('label.input-_position input').set(@last_item_on_first_page._position - 1)
      find_link('Save').click
      # Reload page
      visit('/admin')
      select_last_module_from_list(list_of_modules)

      assert page.has_css?('div.item-title', count: @loaded_items)
      assert page.has_content?('10 ways to lose weight')
      assert_not page.has_css?("a[data-id='#{@last_item_on_first_page.id}']")
      scoll_to_bottom
      assert page.has_css?('div.item-title', count: class_name.count)
      assert page.has_css?("a[data-id='#{@last_item_on_first_page.id}']")
    end
  end

end