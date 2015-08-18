require 'rails/generators'
require 'rails/generators/rails/app/app_generator'

module Chr
  module Generators
    class AppGenerator < Rails::Generators::AppGenerator
          
      def finish_template
        invoke :chr_customization
        super
      end

      def chr_customization
        invoke :customize_gemfile
        invoke :setup_development_environment
        invoke :setup_secret_token
        invoke :configure_app
        invoke :remove_routes_comment_lines
        invoke :add_root_path
        invoke :setup_git
        invoke :setup_database
        invoke :setup_spring
        invoke :outro
      end

      def customize_gemfile
        build :replace_gemfile
        build :set_ruby_to_version_being_used

        bundle_command 'install'
      end

      def setup_database
        say 'Setting up database'

        build :initialize_devise
        build :initialize_mongoid
        build :create_user_model
      end

      def setup_development_environment
        say 'Setting up the development environment'
        build :configure_generators
      end

      def setup_secret_token
        say 'Moving secret token out of version control'
        build :setup_secret_token
      end

      def configure_app
        say 'Configuring app'
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

      def setup_spring
        say "Springifying binstubs"
        build :setup_spring
      end

      def add_root_path
        build :add_root_path
      end

      def remove_routes_comment_lines
        build :remove_routes_comment_lines
      end

      def init_git
        build :init_git
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