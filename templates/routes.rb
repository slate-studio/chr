Rails.application.routes.draw do
  
  #-------------------------------------------#
  # Admin authorization
  #-------------------------------------------#
  devise_for :admins,
    path: 'admin',
    controllers: {
      passwords: 'admin/devise_overrides/passwords',
      sessions:  'admin/devise_overrides/sessions'
    }


  namespace :admin do
    get '/'               => 'base#index'
    get '/bootstrap.json' => 'base#bootstrap_data'
    
    # settings
    resources :admins
    resources :redirects
  end


  #-------------------------------------------#
  # Redirects
  #-------------------------------------------#
  get "/*id" => 'redirects#show', :constraints => Constraints::Redirects
  
  root to: "home#index"
end