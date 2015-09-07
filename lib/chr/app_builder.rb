module Chr
  class AppBuilder < Rails::AppBuilder

    def readme
      template 'README.md.erb', 'README.md'
    end


    def replace_gemfile
      remove_file 'Gemfile'
      template 'Gemfile.erb', 'Gemfile'
    end


    def set_ruby_to_version_being_used
      create_file '.ruby-version', "#{Chr::RUBY_VERSION}\n"
    end


    def raise_on_delivery_errors
      replace_in_file 'config/environments/development.rb',
        'raise_delivery_errors = false', 'raise_delivery_errors = true'
    end


    def raise_on_unpermitted_parameters
      config = <<-RUBY
    config.action_controller.action_on_unpermitted_parameters = :raise
      RUBY

      inject_into_class "config/application.rb", "Application", config
    end


    def provide_setup_script
      template "bin_setup.erb", "bin/setup", port_number: port, force: true
      run "chmod a+x bin/setup"
    end


    def provide_dev_prime_task
      copy_file 'development_seeds.rb', 'lib/tasks/development_seeds.rake'
    end


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


    def configure_newrelic
      template 'newrelic.yml.erb', 'config/newrelic.yml'
    end


    def configure_smtp
      copy_file 'smtp.rb', 'config/smtp.rb'

      prepend_file 'config/environments/production.rb',
        %{require Rails.root.join("config/smtp")\n}

      config = <<-RUBY

  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = SMTP_SETTINGS
      RUBY

      inject_into_file 'config/environments/production.rb', config,
        :after => 'config.action_mailer.raise_delivery_errors = false'
    end


    def configure_rack_timeout
      rack_timeout_config = <<-RUBY
  Rack::Timeout.timeout = (ENV["RACK_TIMEOUT"] || 10).to_i
      RUBY

      append_file "config/environments/production.rb", rack_timeout_config
    end


    def enable_rack_canonical_host
      config = <<-RUBY

  # Ensure requests are only served from one, canonical host name
  config.middleware.use Rack::CanonicalHost, ENV.fetch("HOST")
      RUBY

      inject_into_file(
        "config/environments/production.rb",
        config,
        after: serve_static_files_line
      )
    end

    def enable_rack_deflater
      config = <<-RUBY

  # Enable deflate / gzip compression of controller-generated responses
  config.middleware.use Rack::Deflater
      RUBY

      inject_into_file(
        "config/environments/production.rb",
        config,
        after: serve_static_files_line
      )
    end


    def setup_asset_host
      replace_in_file 'config/environments/production.rb',
        "# config.action_controller.asset_host = 'http://assets.example.com'",
        'config.action_controller.asset_host = ENV.fetch("ASSET_HOST")'

      replace_in_file 'config/initializers/assets.rb',
        "config.assets.version = '1.0'",
        'config.assets.version = (ENV["ASSETS_VERSION"] || "1.0")'

      inject_into_file(
        "config/environments/production.rb",
        '  config.static_cache_control = "public, max-age=#{1.year.to_i}"',
        after: serve_static_files_line
      )
    end


    def setup_asset_sync
      copy_file 'asset_sync.rb', 'config/initializers/asset_sync.rb'
    end


    def setup_staging_environment
      staging_file = 'config/environments/staging.rb'
      copy_file 'staging.rb', staging_file

      config = <<-RUBY

  Rails.application.configure do
  # ...
  end
      RUBY

      append_file staging_file, config
    end


    def setup_secret_token
      template 'secrets.yml', 'config/secrets.yml', force: true
    end


    def create_partials_directory
      empty_directory 'app/views/application'
    end


    def create_shared_analytics
      copy_file '_analytics.html.erb', 'app/views/application/_analytics.html.erb'
    end


    def create_shared_flashes
      copy_file '_flashes.html.erb', 'app/views/application/_flashes.html.erb'
    end


    def create_shared_javascripts
      copy_file '_javascript.html.erb', 'app/views/application/_javascript.html.erb'
    end


    def create_application_layout
      template 'application_layout.html.erb.erb',
        'app/views/layouts/application.html.erb',
        force: true
    end


    def create_body_class_helper
      copy_file 'body_class_helper.rb', 'app/helpers/body_class_helper.rb'
    end


    def configure_action_mailer
      action_mailer_host "development", %{"localhost:#{port}"}
      action_mailer_host "test", %{"www.example.com"}
      action_mailer_host "staging", %{ENV.fetch("HOST")}
      action_mailer_host "production", %{ENV.fetch("HOST")}
    end


    def configure_puma
      copy_file "puma.rb", "config/puma.rb"
    end


    def setup_foreman
      copy_file 'sample.env', '.sample.env'
      copy_file 'Procfile', 'Procfile'
    end


    def setup_stylesheets
      remove_file "app/assets/javascripts/application.js"
      copy_file "application.coffee",
                "app/assets/javascripts/application.coffee"
    end


    def setup_javascripts
      remove_file "app/assets/stylesheets/application.css"
      copy_file "application.scss",
                "app/assets/stylesheets/application.scss"
    end


    def copy_miscellaneous_files
      copy_file "errors.rb", "config/initializers/errors.rb"
      copy_file "json_encoding.rb", "config/initializers/json_encoding.rb"
    end


    def customize_error_pages
      meta_tags =<<-EOS
  <meta charset="utf-8" />
  <meta name="ROBOTS" content="NOODP" />
  <meta name="viewport" content="initial-scale=1" />
      EOS

      %w(500 404 422).each do |page|
        inject_into_file "public/#{page}.html", meta_tags, after: "<head>\n"
        replace_in_file "public/#{page}.html", /<!--.+-->\n/, ''
      end
    end


    def setup_devise
      generate 'devise:install'

      replace_in_file 'config/initializers/devise.rb',
        '# config.scoped_views = false',
        'config.scoped_views = true'

      replace_in_file 'config/initializers/devise.rb',
        '# config.sign_out_all_scopes = true',
        'config.sign_out_all_scopes = false'
    end


    def setup_character_routes
      remove_file 'config/routes.rb'
      copy_file 'routes.rb', 'config/routes.rb'
    end


    def setup_character_base_controller
      copy_file 'character_base_controller.rb', 'app/controllers/admin/base_controller.rb'
    end


    def configure_devise_for_character
      copy_file 'devise_overrides_passwords_controller.rb', 'app/controllers/admin/devise_overrides/passwords_controller.rb'
      copy_file 'devise_overrides_sessions_controller.rb',  'app/controllers/admin/devise_overrides/sessions_controller.rb'

      copy_file 'devise_overrides_passwords_edit.html.erb', 'app/views/admin/devise_overrides/passwords/edit.html.erb'
      copy_file 'devise_overrides_passwords_new.html.erb',  'app/views/admin/devise_overrides/passwords/new.html.erb'
      copy_file 'devise_overrides_sessions_new.html.erb',   'app/views/admin/devise_overrides/sessions/new.html.erb'
    end


    def setup_character_views
      copy_file 'character_admin_layout.html.erb', 'app/views/layouts/admin.html.erb'
      copy_file 'character_admin_index.html.erb',  'app/views/admin/index.html.erb'
    end


    def setup_character_stylesheets
      template 'character_admin.coffee.erb', 'app/assets/javascripts/admin.coffee'
    end


    def setup_character_javascripts
      copy_file 'character_admin.scss', 'app/assets/stylesheets/admin.scss'
    end


    def setup_character_assets
      replace_in_file 'config/initializers/assets.rb',
        "# Rails.application.config.assets.precompile += %w( search.js )",
        'Rails.application.config.assets.precompile += %w( admin.js admin.css )'
    end


    def setup_carrierwave
      copy_file "carrierwave.rb", "config/initializers/carrierwave.rb"
    end


    def init_git
      run 'git init'
    end


    def gitignore_files
      remove_file '.gitignore'
      template 'application_gitignore', '.gitignore'
    end


    def initialize_mongoid
      generate 'mongoid:config'
    end


    def setup_bundler_audit
      copy_file "bundler_audit.rake", "lib/tasks/bundler_audit.rake"
      append_file "Rakefile", %{\ntask default: "bundler:audit"\n}
    end


    def setup_spring
      bundle_command "exec spring binstub --all"
    end


    private

      def port
        3000
      end


      def serve_static_files_line
        "config.serve_static_files = ENV['RAILS_SERVE_STATIC_FILES'].present?\n"
      end


      def replace_in_file(relative_path, find, replace)
        path     = File.join(destination_root, relative_path)
        contents = IO.read(path)

        unless contents.gsub!(find, replace)
          raise "#{ find.inspect } not found in #{ relative_path }"
        end

        File.open(path, "w") { |file| file.write(contents) }
      end


      def action_mailer_host(rails_env, host)
        config = "config.action_mailer.default_url_options = { host: #{host} }"
        configure_environment(rails_env, config)
      end


      def configure_environment(rails_env, config)
        inject_into_file(
          "config/environments/#{rails_env}.rb",
          "\n\n  #{config}",
          before: "\nend"
        )
      end

  end
end



