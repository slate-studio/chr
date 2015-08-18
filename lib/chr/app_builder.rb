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

    def setup_secret_token
      template 'secrets.yml', 'config/secrets.yml', force: true
    end

    def initialize_devise
      generate 'devise:install'
    end

    def initialize_mongoid
      generate 'mongoid:config'
    end

    def create_user_model
      generate 'mongoid:devise user'
    end

    def replace_gemfile
      remove_file 'Gemfile'
      template 'Gemfile.erb', 'Gemfile'
    end

    def set_ruby_to_version_being_used
      create_file '.ruby-version', "#{Chr::RUBY_VERSION}\n"
    end

    def configure_simple_form
      bundle_command "exec rails generate simple_form:install"
    end

    def init_git
      run 'git init'
    end

    def setup_spring
      bundle_command "exec spring binstub --all"
    end

    def add_root_path
      inject_into_file(
          "config/routes.rb",
          "\n\n\troot to: \"home#index\"",
          after: "Application.routes.draw do",
        )
    end
    
    def remove_routes_comment_lines
      replace_in_file 'config/routes.rb',
        /Application\.routes\.draw do.*end/m,
        "Application.routes.draw do\nend"
    end
  end
end
