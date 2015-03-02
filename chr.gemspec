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
  s.summary     = 'A simple and lightweight library for building data management web apps'
  s.description = <<-DESC
Character is a library written in CoffeeScript with a help of jQuery that allows to
build data management web applications like CMS, news reader, email client etc. in a
very fast and flexible way. It's responsive by default and supports a few data stores
out of the box: Rails, Firebase and localStorage.
  DESC

  s.rubyforge_project = 'chr'

  s.files         = `git ls-files`.split("\n")
  s.require_paths = ['lib']

  s.add_dependency('bourbon')
  s.add_dependency('jquery-rails')
  s.add_dependency('coffee-rails')
  s.add_dependency('modernizr-rails')
  s.add_dependency('normalize-rails')
end




