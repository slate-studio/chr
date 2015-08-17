module CharacterRestArrayTest

  def urlParams(factory_name, class_name, list_of_modules, config)
    test 'Select Items Only From Scope' do
      create_n_objects(20, factory_name)
      visit('/admin')
      wait_for_ajax
      select_last_module_from_list(list_of_modules)
      assert page.has_css?('div.item-title', count: config[:urlParams].count)
      config[:urlParams].each do |article|
        assert page.has_css?("a[data-id='#{article.id}']")
      end
    end
  end


  def remove_from_scope(factory_name, class_name, list_of_modules, config)
    test 'Remove From Scope' do
      create_n_objects(20, factory_name)
      first_element_from_scope = config[:urlParams].first
      count_elements_in_scope_before = config[:urlParams].count
      show_form_of_item(list_of_modules, first_element_from_scope.id)
      find('label.input-description textarea').set("New sports diet")
      find_link('Save').click
      wait_for_ajax
      # Reload page
      visit('/admin')
      select_last_module_from_list(list_of_modules)
      assert_not page.has_content?('New sports diet')
      assert page.has_css?('div.item-title', count: count_elements_in_scope_before-1)
    end
  end

end