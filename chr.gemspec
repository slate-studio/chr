# coding: utf-8
$:.push File.expand_path('../lib', __FILE__)
require 'chr/version'

Gem::Specification.new do |s|
  s.name        = 'chr'
  s.version     = Chr::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Alexander Kravets']
  s.email       = 'alex@slatestudio.com'
  s.license     = 'MIT'
  s.homepage    = 'http://slatestudio.com'
  s.summary     = 'Powerful responsive javascript CMS for apps'
  s.description = <<-DESC
Character is a library written in CoffeeScript with a help of jQuery that allows to
build data management web applications in a fast and flexible way, e.g. CMS, news reader,
email client etc. It's responsive by default and designed to be data source independent.
  DESC

  s.rubyforge_project = 'chr'

  s.files         = `git ls-files`.split("\n")
  s.require_paths = ['lib']

  s.add_dependency('bourbon',         '>= 3.2')
  s.add_dependency('coffee-rails',    '>= 4.0')
  s.add_dependency('normalize-rails', '>= 3.0')
end




