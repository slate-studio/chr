module Admin
  class DeviseOverrides::SessionsController < Devise::SessionsController
    layout 'admin'
    before_filter :update_return_to, only: %w(new)

    def after_sign_in_path_for(resource)
      "#{admin_path}##{stored_location_for(resource)}"
    end

    def after_sign_out_path_for(resource)
      new_admin_user_session_path
    end

    private

    def update_return_to
      session["admin_user_return_to"] = params[:return_to]
    end
  end
end
