# encoding: utf-8
require 'rubygems'
require 'bundler/setup'
require 'bundler/gem_tasks'
require 'rake/testtask'
require 'rdoc/task'

# Workaround for run konacha tests from gem
$:.unshift File.dirname(__FILE__)
require 'test/test_js_run_config'

desc 'Default: run tests for all ORMs.'
task default: :test
desc 'Run Character unit tests.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = true
  t.warning = false
end

