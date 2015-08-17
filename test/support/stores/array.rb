module CharacterArrayTest

  def sortReverse_by_position(factory_name, class_name, list_of_modules)
    test 'Sort Reverse by Position' do
      create_n_objects(10, factory_name)
      last_item = @instances_of_class.last
      n = 2
      visit('/admin')
      wait_for_ajax
      select_last_module_from_list(list_of_modules)
      while @instances_of_class.count+1 > n do
        title = find("a[data-id='#{@instances_of_class[@instances_of_class.count-n+1].id}']+a").text
        assert_equal title, @instances_of_class[@instances_of_class.count-n].title
        n += 1
      end
      assert page.has_css?('a.is-object div.item-title', count: class_name.count)
    end
  end

end