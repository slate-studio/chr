Rails.application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  namespace :admin do
    
    get '/'               => 'base#index'
    get '/bootstrap.json' => 'base#bootstrap_data'
  
    resources :articles
  
  end

end
