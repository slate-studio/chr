class Admin::BaseController < ActionController::Base
  protect_from_forgery

  before_action :authenticate_admin!


  def index
    render '/admin/index', layout: 'admin'
  end


  def bootstrap_data
    render json: {}
  end

end
