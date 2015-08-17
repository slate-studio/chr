module CharacterViewTest

  def show_item(factory_name, list_of_modules)
    test 'Select Item and render its fields' do
      instance_of_class = FactoryGirl.create(factory_name)
      visit('/admin')
      wait_for_ajax
      # Select Module
      select_last_module_from_list(list_of_modules)
      # Select Item 
      find("div.item-title", :text => instance_of_class.title).click
      wait_for_ajax
      assert page.has_css?("section.view.#{list_of_modules.last}")
    end
  end


  def chage_title(factory_name, class_name, list_of_modules)
    test 'Change Title of Item' do
      instance_of_class = FactoryGirl.create(factory_name)
      show_form_of_item(list_of_modules, instance_of_class.id)
      find('label.input-title input').set("New sports diet")
      find_link('Save').click
      wait_for_ajax
      assert page.has_content?('New sports diet')
      assert_equal class_name.first.title, 'New sports diet'
    end
  end


  def add_item(factory_name, class_name, list_of_modules)
    test 'Add Item' do
      instance_of_class = FactoryGirl.create(factory_name)
      count_of_objects = class_name.count
      visit('/admin')
      wait_for_ajax
      # Select Module
      select_last_module_from_list(list_of_modules)
      # Click "+" 
      get_path_from_modules_list(list_of_modules)
      find("a[href='##{@path}/new']").click
      find('label.input-title input').set("10 ways to lose weight")
      find_link('Save').click
      wait_for_ajax
      assert page.has_content?('10 ways to lose weight')
      assert_equal count_of_objects + 1, class_name.count
    end
  end


  def delete_item(factory_name, class_name, list_of_modules)
    test 'Delete Item' do
      instance_of_class = FactoryGirl.create(factory_name)
      count_of_objects = class_name.count
      show_form_of_item(list_of_modules, instance_of_class.id)
      find_link('Delete').click
      wait_for_ajax
      assert_not page.has_content?(instance_of_class.title)
      assert_equal count_of_objects - 1, class_name.count
    end
  end


  def open_item_and_close(factory_name, list_of_modules)
    test 'Open Item and Close (checking button "Close")' do
      instance_of_class = FactoryGirl.create(factory_name)
      show_form_of_item(list_of_modules, instance_of_class.id)
      get_path_from_modules_list(list_of_modules)
      find("a[href='##{@path}']", :text => 'Close').click
      wait_for_ajax
      assert_not page.has_css?("section.view.#{list_of_modules.last}")
    end
  end


  def disable_delete(factory_name, list_of_modules)
    test 'DisableDelete: true' do
      instance_of_class = FactoryGirl.create(factory_name)
      show_form_of_item(list_of_modules, instance_of_class.id)
      assert_not page.has_css?('a.view-delete', :text => 'Delete')
    end
  end


  def disable_save(factory_name, list_of_modules)
    test 'DisableSave: true' do
      instance_of_class = FactoryGirl.create(factory_name)
      show_form_of_item(list_of_modules, instance_of_class.id)
      assert_not page.has_css?('a.save', :text => 'Save')
    end
  end


  def fullsize_view(factory_name, list_of_modules)
    test 'FullsizeView: true' do
      instance_of_class = FactoryGirl.create(factory_name)
      show_form_of_item(list_of_modules, instance_of_class.id)
      assert page.has_css?('section.fullsize')
    end
  end


  def add_class_active(factory_name, list_of_modules)
    test 'Adding Class Active' do
      instance_of_class = FactoryGirl.create(factory_name)
      show_form_of_item(list_of_modules, instance_of_class.id)
      assert page.has_css?("a.menu-#{list_of_modules.first}.active")
      assert page.has_css?("a[href='##{@path}/view/#{instance_of_class.id}'].active")
    end
  end

end