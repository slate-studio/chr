require 'chr/version'
require 'chr/generators/app_generator'
require 'chr/app_builder'

require 'rails'
require 'bourbon'
require 'formagic'
require 'jquery-rails'
require 'coffee-rails'
require 'sass-rails'

module Chr
  if defined?(Rails) && defined?(Rails::Engine)
    class Engine < ::Rails::Engine
      require 'chr/engine'
    end
  end
end
