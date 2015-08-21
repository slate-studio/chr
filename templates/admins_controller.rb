class Admin::RedirectsController < Admin::BaseController
  mongosteen

  csv_config({ only: [ :old_path, :new_path ] })
end