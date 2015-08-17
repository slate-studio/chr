module CharacterReorderTest

  def reorder(factory_name, class_name, list_of_modules)
    test 'Reorder Items' do
      create_n_objects(3, factory_name)
      position_0_before = class_name.find(@instances_of_class[0].id)._position
      position_1 = class_name.find(@instances_of_class[1].id)._position
      position_2 = class_name.find(@instances_of_class[2].id)._position
      visit('/admin')
      wait_for_ajax
      # Select Module
      select_last_module_from_list(list_of_modules)
      drag_item(@instances_of_class[0], @instances_of_class[1])
      position_0_after = class_name.find(@instances_of_class[0].id)._position
      title_2 = find("a[data-id='#{@instances_of_class[0].id}']+a").text
      title_0 = find("a[data-id='#{@instances_of_class[1].id}']+a").text

      assert page.has_css?('div.item-title', text: @instances_of_class[0].title, count: 1)
      assert_not_equal position_0_before, position_0_after
      assert position_0_after > position_1 && position_0_after < position_2
      assert_equal @instances_of_class[0].title, title_0
      assert_equal @instances_of_class[2].title, title_2    
    end
  end


  def reorder_to_begin_of_list(factory_name, class_name, list_of_modules)
    test 'Reorder Item in Begining of List' do
      create_per_page_plus_n_objects(2, factory_name)
      visit('/admin')
      wait_for_ajax
      select_last_module_from_list(list_of_modules)
      wait_for_ajax
      assert page.has_css?('div.item-title', count: @loaded_items)
      scoll_to_bottom
      wait_for_ajax
      scoll_to_bottom
      drag_item(@last_item, @first_item)
      title_second_item = find("a[data-id='#{@last_item.id}']+a").text
      assert page.has_css?('div.item-title', count: class_name.count)
      assert_equal @first_item.title, title_second_item
    end
  end

end