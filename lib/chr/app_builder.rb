module Chr
  class AppBuilder < Rails::AppBuilder
    include Chr::Actions

    def configure_generators
      config = <<-RUBY

      config.generators do |generate|
        generate.helper false
        generate.javascript_engine false
        generate.stylesheets false
      end

      RUBY

      inject_into_class 'config/application.rb', 'Application', config
    end

    def initialize_devise
      generate 'devise:install'
    end

    def initialize_mongoid
      generate 'mongoid:config'
    end

    def create_user_model
      generate 'mongoid:devise admin'
    end

    def create_home_page
      generate 'controller home index'
    end

    def replace_gemfile
      remove_file 'Gemfile'
      template 'Gemfile.erb', 'Gemfile'
    end

    def set_ruby_to_version_being_used
      create_file '.ruby-version', "#{Chr::RUBY_VERSION}\n"
    end

    def gitignore_files
      remove_file '.gitignore'
      template '.gitignore', '.gitignore'
    end

    def setup_assets
      remove_file 'app/assets/javascripts/application.js'
      template 'application.coffee', 'app/assets/javascripts/application.coffee'

      remove_file 'app/assets/javascripts/admin.coffee'
      template 'admin.coffee', 'app/assets/javascripts/admin.coffee'

      remove_file 'app/assets/stylesheets/admin.scss'
      template 'admin.scss', 'app/assets/stylesheets/admin.scss'
      
      copy_file 'redactor.js', 'app/assets/javascripts/redactor.js'
      copy_file 'redactor.scss', 'app/assets/stylesheets/redactor.scss'

      # replace_in_file 'config/initializers/assets.rb',
      #   "# Rails.application.config.assets.precompile += %w( search.js )",
      #   'Rails.application.config.assets.precompile += %w( admin.js admin.css )'
    end

    def replace_misc_files
      remove_file 'app/controllers/admins_controller.rb'
      template 'admins_controller.rb', 'app/controllers/admins_controller.rb'

      copy_file 'base_controller.rb', 'app/controllers/admin/base_controller.rb'
      copy_file 'devise_overrides_passwords_controller.rb', 'app/controllers/admin/devise_overrides/passwords_controller.rb'
      copy_file 'devise_overrides_sessions_controller.rb', 'app/controllers/admin/devise_overrides/sessions_controller.rb'

      remove_file 'app/models/admin.rb'
      template 'admin.rb', 'app/models/admin.rb'

      copy_file 'layouts_admin.html.erb', 'app/views/layouts/admin.html.erb'

      copy_file 'devise_overrides_passwords_edit.html.erb', 'app/views/admin/devise_overrides/passwords/edit.html.erb'
      copy_file 'devise_overrides_passwords_new.html.erb', 'app/views/admin/devise_overrides/passwords/new.html.erb'
      copy_file 'devise_overrides_sessions_new.html.erb', 'app/views/admin/devise_overrides/sessions/new.html.erb'
      copy_file 'admin_index.html.erb', 'app/views/admin/index.html.erb'

      inject_into_file(
              "config/environments/development.rb",
              "  config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }",
              before: "end",
      )
    end

    # def configure_simple_form
    #   bundle_command "exec rails generate simple_form:install"
    # end

    def init_git
      run 'git init'
    end

    def setup_spring
      bundle_command "exec spring binstub --all"
    end

    def replace_routes
      remove_file 'config/routes.rb'
      template 'routes.rb', 'config/routes.rb'
    end
  end
end
