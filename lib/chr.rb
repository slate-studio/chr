require "chr/version"
require "rails"
require "bourbon"
require "formagic"
require "jquery-rails"
require "coffee-rails"
require "sass-rails"
require "font-awesome-rails"

module Chr
  if defined?(Rails) && defined?(Rails::Engine)
    class Engine < ::Rails::Engine
      require "chr/engine"
    end
  end
end
