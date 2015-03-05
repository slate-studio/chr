# CodeKit needs relative paths
dir = File.dirname(__FILE__)
$LOAD_PATH.unshift dir unless $LOAD_PATH.include?(dir)

require 'normalize-rails'
require 'bourbon'

module Chr
  if defined?(Rails) && defined?(Rails::Engine)
    class Engine < ::Rails::Engine
      require 'chr/engine'
    end
  else
    # not a rails project, need to include sass and javascript folders
    #bourbon_path = File.expand_path("../../app/assets/stylesheets", __FILE__)
    #ENV["SASS_PATH"] = [ENV["SASS_PATH"], bourbon_path].compact.join(File::PATH_SEPARATOR)
  end
end
