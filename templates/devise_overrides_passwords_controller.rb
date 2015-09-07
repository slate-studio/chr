class Admin::DeviseOverrides::PasswordsController < Devise::PasswordsController
  layout 'admin'

  protected

    def after_resetting_password_path_for(resource)
      admin_path
    end

end