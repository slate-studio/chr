require 'chr/version'
require 'chr/generators/app_generator'
require 'chr/actions'
require 'chr/app_builder'

require 'bourbon'

module Chr
  if defined?(Rails) && defined?(Rails::Engine)
    class Engine < ::Rails::Engine
      require 'chr/engine'
    end
  end
end
