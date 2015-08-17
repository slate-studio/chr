module CharacterListTest

  def show_with_parent(factory_name, list_of_modules)
    test 'ShowWithParent: true' do
      get_path_from_modules_list(list_of_modules)
      instance_of_class = FactoryGirl.create(factory_name)
      visit('/admin')
      wait_for_ajax
      # Select Module
      select_last_module_from_list(list_of_modules)
      assert page.has_css?("a[data-id='#{list_of_modules.last}']")
      assert page.has_css?("a[data-id='#{instance_of_class.id}']")
      assert page.has_css?('div.list-aside')
    end
  end


  def disable_new_item(factory_name, list_of_modules)
    test 'DisableNewItems: true' do
      instance_of_class = FactoryGirl.create(factory_name)
      visit('/admin')
      wait_for_ajax
      # Select Module
      select_last_module_from_list(list_of_modules)
      get_path_from_modules_list(list_of_modules)
      assert_not page.has_css?("a[href='##{@path}/new']")
    end
  end


end