module CharacterUploaderTest

  def add_image(factory_name, list_of_modules)
    test 'Add Image' do
      instance_of_class = FactoryGirl.create(factory_name)
      show_form_of_item(list_of_modules, instance_of_class.id)
      upload_test_image_and_save
      assert page.has_css?("a[data-id='#{instance_of_class.id}'] div img")
      assert page.has_css?("input[name='[remove_image]']")
      assert page.has_css?('a', text: 'test.jpg')
    end
  end


  def remove_image(factory_name, list_of_modules)
    test 'Remove Image' do
      instance_of_class = FactoryGirl.create(factory_name)
      show_form_of_item(list_of_modules, instance_of_class.id)
      upload_test_image_and_save
      assert page.has_css?("a[data-id='#{instance_of_class.id}'] div img")
      assert page.has_css?("input[name='[remove_image]']")
      assert page.has_css?('a', text: 'test.jpg')
      find("input[name='[remove_image]']").click
      find_link('Save').click
      wait_for_ajax
      assert_not page.has_css?("a[data-id='#{instance_of_class.id}'] div img")
      assert_not page.has_css?("input[name='[remove_image]']")
      assert_not page.has_css?('a', text: 'test.jpg')
    end
  end

end