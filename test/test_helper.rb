# For get coverage local - uncomment 4-7 lines
require 'coveralls'
Coveralls.wear!('rails')
# SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
#   SimpleCov::Formatter::HTMLFormatter,
#   Coveralls::SimpleCov::Formatter
# ]
ENV['RAILS_ENV'] ||= 'test'
$:.unshift File.dirname(__FILE__)

require 'rails_app/config/environment'
require 'rails/test_help'
require 'devise'
require 'database_cleaner'
require 'capybara/rails'
require 'capybara/dsl'
require 'capybara-screenshot/minitest'
require 'factory_girl'
Dir[Rails.root.join("../support/**/*.rb")].each{ |f| require f }

# DatabaseCleaner
DatabaseCleaner.strategy = :truncation
DatabaseCleaner.clean_with(:truncation)

# Minitest::Reporters
Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

# Capybara
Capybara.default_driver             = :webkit
Capybara.default_wait_time          = 10
Capybara::Screenshot.prune_strategy = :keep_last_run


class ActiveSupport::TestCase
    def setup
    DatabaseCleaner.start
  end

  def teardown
    DatabaseCleaner.clean
  end

  def wait_for_ajax
    Timeout.timeout(Capybara.default_wait_time) do
      loop do
        active = page.evaluate_script('$.active').to_i
        break if active == 0
      end
    end
  end

  # Add more helper methods to be used by all tests here...
end

# ActionDispatch
include CharacterFrontEnd
class ActionDispatch::IntegrationTest
  include Capybara::DSL

  def setup
    DatabaseCleaner.start
  end

  def teardown
    Capybara.reset_sessions!
    Capybara.use_default_driver
    DatabaseCleaner.clean
  end
end