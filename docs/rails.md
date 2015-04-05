# Character

## Rails

An example of admin implementation setup for [Rails](https://github.com/rails/rails) app that uses [Mongoid](https://github.com/mongoid/mongoid) stack.


### Gems

Add to following gems to ```Gemfile```:

    gem "devise"
    gem "mongosteen"
    gem "chr"

This example uses ```devise``` for admins authentication.


### Admin authentication

Start with running [devise](https://github.com/plataformatec/devise) generator:

    rails generate devise:install

Setup ```Admin``` model with devise generator:

    rails generate devise admin

Here is an example of basic ```app/models/admin.rb``` model that provides email/password authentication:

```ruby
class Admin
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::SerializableId

  devise :database_authenticatable,
         :rememberable,
         :authentication_keys => [ :email ]

  ## Database authenticatable
  field :email,              type: String, default: ""
  field :encrypted_password, type: String, default: ""

  ## Rememberable
  field :remember_created_at, type: Time
end
```

When models are ready, setup controllers, views and configure routes.

Base admin controller ```app/controllers/admin/base_controller.rb``` looks like this:

```ruby
class Admin::BaseController < ActionController::Base
  protect_from_forgery

  if Rails.env.production?
    before_action :authenticate_admin!
  end

  def index
    render '/admin/index', layout: 'admin'
  end

  def bootstrap_data
    render json: {}
  end
end
```

Notes on code above:

  1. Authentication is not required when running in development or testing environment;
  2. Need to setup ```index``` view and ```admin``` layout to render admin app;
  3. ```bootstrap_data``` is a placeholder for objects that might be required to be loaded when app starts.

Devise would require a custom ```SessionController``` implementation in ```app/controllers/admin/devise_overrides/session_controller.rb```. ```SessionController``` sets ```admin``` layout to be used for devise views rendering and enables login by email (*looks like workaround*).

```ruby
class Admin::DeviseOverrides::SessionsController < Devise::SessionsController
  layout 'admin'

  protected

    def configure_permitted_parameters
      devise_parameter_sanitizer.for(:sign_in) << :email
    end
end
```

Admin app layout ```app/views/layouts/admin.html.erb```:

```erb
<!doctype html>
<html>
  <head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, minimum-scale=1, user-scalable=no">
    <meta name="apple-mobile-web-app-capable" content="yes">
    <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
    <title>Admin</title>
    <%= csrf_meta_tags %>
    <%= stylesheet_link_tag :admin, media: "all" %>
  </head>

  <%= yield %>
</html>
```

Admin index view ```app/views/admin/index.html.erb```:

```erb
<body class='loading'>
  <%= link_to 'Sign Out', destroy_admin_session_path, method: :delete, style: 'display:none;' %>
</body>
<%= javascript_include_tag :admin %>
```

New session view for devise ```app/views/admin/devise_overrides/sessions/new.html.erb```:

```erb
<body class='sign-in'>
  <h2>Sign In</h2>

  <%= simple_form_for(resource, as: resource_name, url: session_path(resource_name)) do |f| %>
    <% if alert %>
      <p class="error"><%= alert.gsub('username', 'email').gsub('or sign up', '') %></p>
    <% end %>

    <div class="form-inputs">
      <%= f.input :email,    required: true, autofocus: true %>
      <%= f.input :password, required: true %>

      <%= f.input :remember_me, as: :boolean if devise_mapping.rememberable? %>
    </div>

    <div class="form-actions">
      <%= f.button :submit, "Sign In" %>
    </div>
  <% end %>
</body>
```

Now connect admin and devise in ```config/routes.rb``` with:

```ruby
devise_for :admins, path: "admin", controllers: { sessions: "admin/devise_overrides/sessions" }
namespace :admin do
  get '/'               => 'base#index'
  get '/bootstrap.json' => 'base#bootstrap_data'
end
```


### Character setup

Three pieces to be configured here.

**First**: create ```app/assets/javascripts/admin.coffee``` with empty ```modules``` configuration:

```coffee
#= require jquery
#= require jquery_ujs
#= require chr

$ ->
  $.get '/admin/bootstrap.json', (response) ->
    config =
      modules: {}

    $('body').removeClass('loading')
    chr.start(config)

    # append signout button to the end of sidebar menu
    $('a[data-method=delete]').appendTo(".sidebar .menu").show()
```

**Second**: create foundation for style customization in ```app/assets/stylesheets/admin.scss```:

```scss
@charset "utf-8";

@import "normalize-rails";
@import "chr";
@import "admin/signin";
```

Last import in the code above is optional. But here is a default source for it as well ```app/assets/stylesheets/admin/chr/_signin.scss```:

```scss
.sign-in {
  margin: 2em; max-width: 18em;

  h2 { text-transform: uppercase; color: $black; }
  input { @include noFocus(); }
  label { color: $black; }
  .input { margin-bottom: .75em; }

  .input input[type=checkbox] { margin-right: .5em; }

  .input input.email, .input input.password {
    float: right; margin: -2px 0 0; width: 12em;
    border: 0; border-bottom: 1px solid $contrastColor;
  }

  .input.boolean { margin-top: 1.25em; }

  .form-actions input {
    width: 100%; padding: 1em 2em; margin-top: .75em;
    color: $white; background-color: $positiveColor; border: 0;
  }
}

```

**Third**: make sure admin assets are precompiled on production, include ```admin.js``` and ```admin.css``` in ```config/initializers/assets.rb```:

```ruby
Rails.application.config.assets.precompile += %w( admin.js admin.css )
```

At this point initial setup for admin app is finished and it could be accessed via: ```localhost:3000/admin```.


### Add models

To be continued...




