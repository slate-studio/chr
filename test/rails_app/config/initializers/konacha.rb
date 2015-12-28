Konacha.configure do |config|
  require 'capybara/webkit'

  config.spec_dir     = "test/javascripts"
  config.spec_matcher = /_test\./
  config.stylesheets  = %w(application)
  config.driver       = :webkit
end if defined?(Konacha)