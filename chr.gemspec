# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'chr/version'
require 'date'

Gem::Specification.new do |s|
  s.required_ruby_version = ">= #{Chr::RUBY_VERSION}"

  s.authors = [ 'Alexander Kravets', 'Denis Popov', 'Roman Brazhnyk' ]
  s.email   = 'alex@slatestudio.com'
  s.date    = Date.today.strftime('%Y-%m-%d')

  s.description = <<-DESC
Character is a library written in CoffeeScript with a help of jQuery that allows to
build data management web applications in a fast and flexible way, e.g. CMS, news reader,
email client etc. It's responsive by default and designed to be data source independent.
  DESC

  s.name             = 'chr'
  s.summary          = 'Character is powerful responsive javascript-based CMS.'
  s.homepage         = 'http://github.com/slate-studio/chr'
  s.extra_rdoc_files = %w[README.md LICENSE]
  s.license          = 'MIT'
  s.files            = `git ls-files`.split("\n")
  s.test_files       = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths    = [ 'lib' ]
  s.executables      = [ 'chr' ]
  s.version          = Chr::VERSION
  s.platform         = Gem::Platform::RUBY

  s.add_dependency 'rails', Chr::RAILS_VERSION
  s.add_dependency 'coffee-rails', '>= 4.0'
  s.add_dependency 'formagic', '>= 0.2.8'
  s.add_dependency 'jquery-rails'
  s.add_dependency 'sass-rails'
  s.add_dependency 'bourbon'
  s.add_dependency 'font-awesome-rails'

  # tests
  s.add_development_dependency 'mongosteen', '>= 0.2'
  s.add_development_dependency 'ants', '>= 0.3'
  s.add_development_dependency 'carrierwave-mongoid'
  s.add_development_dependency 'mini_magick'

  s.add_development_dependency 'faker'
  s.add_development_dependency 'coveralls'
  s.add_development_dependency 'uglifier'
  s.add_development_dependency 'database_cleaner'
  s.add_development_dependency 'factory_girl_rails'
  s.add_development_dependency 'capybara-webkit'
  s.add_development_dependency 'capybara-screenshot'
  s.add_development_dependency 'selenium-webdriver'
  s.add_development_dependency 'minitest-reporters'
end