class Admin::BaseController < ActionController::Base
  protect_from_forgery

  def index
    render '/admin/index', layout: 'admin'
  end
end
