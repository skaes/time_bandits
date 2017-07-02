require 'bundler'
Bundler::GemHelper.install_tasks

require 'rake/testtask'
include Rake::DSL

$:.unshift 'lib'
require 'time_bandits'

task :default => :test

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = true
end

namespace :appraisal do
  task :install do
    abort unless system("appraisal install")
  end
  task :test => :install do
    abort unless system("appraisal rake test")
  end
end
