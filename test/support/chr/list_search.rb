module CharacterSearchTest
 
  def search(factory_name, list_of_modules)
    test 'Search Item' do
      create_n_objects(3, factory_name)
      visit('/admin')
      wait_for_ajax
      # Select Module
      select_last_module_from_list(list_of_modules)
      wait_for_ajax
      find('div.search a.icon').click
      find('div.search input').set("#{@instances_of_class[0].title}\n")
      wait_for_ajax
      n = 1
      2.times do 
        assert_not page.has_content?(@instances_of_class[n].title)
        n += 1
      end
      assert page.has_content?(@instances_of_class[0].title)
    end
  end


  def search_and_close(factory_name, class_name, list_of_modules)
    test 'Search Item and Cancel (checking button "Cancel")' do
      create_n_objects(3, factory_name)
      visit('/admin')
      wait_for_ajax
      # Select Module
      select_last_module_from_list(list_of_modules)
      find('div.search a.icon').click
      find('div.search input').set("#{@instances_of_class[0].title}\n")
      wait_for_ajax
      find_link('Cancel').click
      class_name.each do |instance|
      assert page.has_content?(instance.title)
      end
    end
  end

end