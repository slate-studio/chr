require 'normalize-rails'
require 'bourbon'

module Chr
  if defined?(Rails) && defined?(Rails::Engine)
    class Engine < ::Rails::Engine
      require 'chr/engine'
      require 'mongoid/character'
    end
  end
end
