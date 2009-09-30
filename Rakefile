require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

require 'rubygems'
require 'rake/gempackagetask'

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the custom_benchmarks plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc 'Generate documentation for the custom_benchmarks plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'Custom Benchmarks'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

spec = Gem::Specification.new do |s|
  s.name = "custom_benchmarks"
  s.version = "0.0.2"
  s.author = "Tyler Kovacs"
  s.email = "tyler.kovacs@zvents.com"
  s.homepage = "http://blog.zvents.com/2006/10/31/rails-plugin-custom-benchmarks"
  s.platform = Gem::Platform::RUBY
  s.summary = "Easily allows custom information to be included in the benchmark log line at the end of each request."
  s.files = FileList["lib/**/*"].to_a
  s.require_path = "lib"
  s.autorequire = "custom_benchmarks"
  s.test_files = FileList["{test}/**/*test.rb"].to_a
  s.has_rdoc = true
  s.extra_rdoc_files = ["README"]
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_tar = true
end
