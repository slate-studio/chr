# Character

## A simple and lightweight library for building data management web apps

## Rails Setup

This an example of admin implementation setup for Rails app that uses mongoid stack.

#### Gemfile setup

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

Or here is an example of basic ```app/models/admin.rb``` model that provides email/password authentication:

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

When models is there let's setup controllers, views and configure routes.

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

A few notes on code above:

  1. Authentication is not required when running in development or testing environment;
  2. Need to setup ```index``` view and ```admin``` layout to render admin app;
  3. ```bootstrap_data``` is a placeholder for objects that might be required to be loaded when app starts.

Devise would require a custom ```SessionController``` implementation, ```app/controllers/admin/devise_overrides/session_controller.rb```:

  ```ruby
  class Admin::DeviseOverrides::SessionsController < Devise::SessionsController
  layout 'admin'

  protected

    def configure_permitted_parameters
      devise_parameter_sanitizer.for(:sign_in) << :email
    end
  end
  ```

This sets ```admin``` layout to be used to render devise views and enables login by email (*looks like workaround*).

```app/views/layouts/admin.html```:

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



## The Character family

- [Mongosteen](https://github.com/slate-studio/mongosteen): An easy way to add restful actions for mongoid models

## Credits

[![Slate Studio](https://slate-git-images.s3-us-west-1.amazonaws.com/slate.png)](http://slatestudio.com)

Character is maintained and funded by [Slate Studio, LLC](http://slatestudio.com). Tweet your questions or suggestions to [@slatestudio](https://twitter.com/slatestudio) and while you’re at it follow us too.

## License

Copyright © 2015 [Slate Studio, LLC](http://slatestudio.com). Character is free software, and may be redistributed under the terms specified in the [license](LICENSE.md).