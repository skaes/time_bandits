require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'time_bandits'
  rdoc.options << '--line-numbers' << '--inline-source' << '--diagram' << '--quiet'
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

task :default => :rdoc
