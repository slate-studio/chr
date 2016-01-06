require 'mongosteen'
require 'factory_girl'
require 'faker'
require 'carrierwave/mongoid'
require 'rails/test_help'
require 'ants'
require 'rails'

require 'test/test_helper'

# js unit tests stored and runs from rails_app/test
# This practice using konacha developers:
# https://github.com/jfirebaugh/konacha/tree/master/spec/dummy/spec/javascripts
namespace :konacha do
  desc "Run JavaScript specs interactively"
  task :serve do
    Konacha.serve
  end

  desc "Run JavaScript specs non-interactively"
  task :run do
    passed = Konacha.run
    exit 1 unless passed
  end
end
