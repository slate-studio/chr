require 'rails/generators'
require 'rails/generators/rails/app/app_generator'

module Chr
  module Generators
    class AppGenerator < Rails::Generators::AppGenerator

      class_option :skip_test_unit, type: :boolean, aliases: "-T", default: true,
        desc: "Skip Test::Unit files"

      class_option :skip_bundle, type: :boolean, aliases: "-B", default: true,
        desc: "Don't run bundle install"
          
      def finish_template
        invoke :chr_customization
        super
      end

      def chr_customization
        invoke :customize_gemfile
        invoke :setup_development_environment
        invoke :configure_app
        invoke :setup_assets
        invoke :setup_git
        invoke :setup_database
        invoke :setup_spring
        invoke :replace_routes
        invoke :replace_misc_files
        invoke :outro
      end

      def customize_gemfile
        build :replace_gemfile
        build :set_ruby_to_version_being_used

        bundle_command 'install'
      end

      def setup_development_environment
        say 'Setting up the development environment'
        build :configure_generators
      end

      def configure_app
        say 'Configuring app'
      end

      def setup_assets
        build :setup_assets
      end

      def replace_routes
        build :replace_routes
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

        build :initialize_devise
        build :initialize_mongoid 
        build :create_user_model
        build :create_home_page
      end

      def setup_spring
        say "Springifying binstubs"
        build :setup_spring
      end

      def replace_misc_files
        build :replace_misc_files
      end

      def outro
        say 'Congratulations! You just pulled our Chr.'
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
end