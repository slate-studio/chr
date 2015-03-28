# Character

*Powerful javascript CMS for apps.*


## Rails

An example of admin implementation setup for [Rails](https://github.com/rails/rails) app that uses [Mongoid](https://github.com/mongoid/mongoid) stack.


#### Gems

Add to following gems to ```Gemfile```:

    gem "devise"
    gem "mongosteen"
    gem "chr"

This example uses ```devise``` for admins authentication.


#### Admin authentication

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
    <%= stylesheet_link_tag    :admin, media: "all" %>
    <%= javascript_include_tag :admin %>
  </head>

  <%= yield %>
</html>
```

Admin index view ```app/views/admin/index.html.erb```:

```erb
<body class='loading'>
  <%= link_to 'Sign Out', destroy_admin_session_path, method: :delete, style: 'display:none;' %>
</body>
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


#### Character setup

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
  font-size: 14px;
  color: #555;
  margin: 3em 0 0 3em;

  h2 {
    text-transform: uppercase;
    font-size: 1em;
    font-size: 16px;
    color: $black;
    margin-bottom: 1.5em;
  }

  p {
    margin: -1.5em 0 2em;
    color: $positiveColor;
  }

  .form-actions, .form-inputs {
    max-width: 280px;
  }

  .input {
    margin-bottom: 1.5em;
  }

  input.string, input.password {
    float: right;
    margin-top: -.45em;
    padding: .25em .5em;
    width: 13.5em;
  }

  label.boolean input {
    margin-right: .25em;
  }

  .form-actions input {
    width: 100%;
    padding: 1em 2em;
    background-color: $positiveColor;
    border: 0;
    color: $white;
  }
}
```

**Third**: make sure admin assets are precompiled on production, include ```admin.js``` and ```admin.css``` in ```config/initializers/assets.rb```:

```ruby
Rails.application.config.assets.precompile += %w( admin.js admin.css )
```

At this point initial setup for admin app is finished and it could be accessed via: ```localhost:3000/admin```.


#### Add models

To be continued...


## The Character family

- [Mongosteen](https://github.com/slate-studio/mongosteen): An easy way to add restful actions for Mongoid models
- [Inverter](https://github.com/slate-studio/inverter): An easy way to connect Rails templates content to Character CMS
- [Loft](https://github.com/slate-studio/loft): Media assets manager for Character CMS

## Credits

[![Slate Studio](https://slate-git-images.s3-us-west-1.amazonaws.com/slate.png)](http://slatestudio.com)

Character is maintained and funded by [Slate Studio, LLC](http://slatestudio.com). Tweet your questions or suggestions to [@slatestudio](https://twitter.com/slatestudio) and while you’re at it follow us too.

## License

Copyright © 2015 [Slate Studio, LLC](http://slatestudio.com). Character is free software, and may be redistributed under the terms specified in the [license](LICENSE.md).