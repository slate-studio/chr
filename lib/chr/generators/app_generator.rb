require 'rails/generators'
require 'rails/generators/rails/app/app_generator'

module Chr
  class AppGenerator < Rails::Generators::AppGenerator


    class_option :skip_active_record, type: :boolean, aliases: "-O", default: true,
      desc: "Skip Active Record files"

    class_option :skip_test_unit, type: :boolean, aliases: "-T", default: true,
      desc: "Skip Test::Unit files"

    class_option :skip_turbolinks, type: :boolean, default: true,
      desc: "Skip turbolinks gem"

    class_option :skip_bundle, type: :boolean, aliases: "-B", default: true,
      desc: "Don't run bundle install"


    def finish_template
      invoke :chr_customization
      super
    end


    def chr_customization
      invoke :customize_gemfile
      invoke :setup_development_environment
      invoke :setup_test_environment
      invoke :setup_production_environment
      invoke :setup_staging_environment
      invoke :setup_secret_token
      invoke :create_application_views
      invoke :configure_app
      invoke :create_application_assets
      invoke :copy_miscellaneous_files
      invoke :customize_error_pages
      invoke :setup_devise
      invoke :setup_character
      invoke :setup_database
      invoke :setup_git
      # invoke :create_heroku_apps
      # invoke :create_github_repo
      invoke :setup_bundler_audit
      #invoke :setup_spring
      invoke :outro
    end


    def customize_gemfile
      build :replace_gemfile
      build :set_ruby_to_version_being_used

      bundle_command 'install'
    end


    def setup_development_environment
      say 'Setting up the development environment'
      #build :raise_on_delivery_errors
      build :raise_on_unpermitted_parameters
      build :provide_setup_script
      build :provide_dev_prime_task
      build :configure_generators
    end


    def setup_test_environment
      say 'Setting up the test environment'
      # @todo
    end


    def setup_production_environment
      say 'Setting up the production environment'
      build :configure_smtp
      build :configure_rack_timeout
      build :enable_rack_canonical_host
      build :enable_rack_deflater
      build :setup_asset_host
    end


    def setup_staging_environment
      say 'Setting up the staging environment'
      build :setup_staging_environment
    end


    def setup_secret_token
      say 'Moving secret token out of version control'
      build :setup_secret_token
    end


    def create_application_views
      say 'Creating application views'
      build :create_partials_directory
      build :create_shared_analytics
      build :create_shared_flashes
      build :create_shared_javascripts
      build :create_application_layout
      build :create_body_class_helper
    end


    def configure_app
      say 'Configuring app'
      build :configure_action_mailer
      build :configure_puma
      build :setup_foreman
    end


    def create_application_assets
      say 'Create application stylesheets and javascripts'
      build :setup_stylesheets
      build :setup_javascripts
    end


    def copy_miscellaneous_files
      say 'Copying miscellaneous support files'
      build :copy_miscellaneous_files
    end


    def customize_error_pages
      say 'Customizing the 500/404/422 pages'
      build :customize_error_pages
    end


    def setup_devise
      say "Setup devise"
      build :setup_devise
    end


    def setup_character
      say "Setup character"
      build :setup_character_routes
      build :setup_character_base_controller
      build :configure_devise_for_character
      build :setup_character_views
      build :setup_character_stylesheets
      build :setup_character_javascripts
      build :setup_character_assets
      build :setup_carrierwave
    end


    def setup_git
      if !options[:skip_git]
        say 'Initializing git'
        invoke :setup_gitignore
        invoke :init_git
      end
    end


    def setup_gitignore
      build :gitignore_files
    end


    def init_git
      build :init_git
    end


    def setup_database
      say 'Setting up database'
      build :initialize_mongoid
    end


    def setup_bundler_audit
      say "Setting up bundler-audit"
      build :setup_bundler_audit
    end


    def setup_spring
      say "Springifying binstubs"
      build :setup_spring
    end


    def outro
      say 'Congratulations! You just created a new Character.'
    end


    protected

      def get_builder_class
        Chr::AppBuilder
      end


      def using_active_record?
        !options[:skip_active_record]
      end

  end
end



