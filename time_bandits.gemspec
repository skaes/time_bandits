# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "time_bandits/version"

Gem::Specification.new do |s|
  s.name        = "time_bandits"
  s.version     = TimeBandits::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Stefan Kaes"]
  s.email       = ["skaes@railsexpress.de"]
  s.homepage    = "https://github.com/skaes/time_bandits/"
  s.summary     = "Custom performance logging for Rails"
  s.description = "Rails Completed Line on Steroids"
  s.license     = 'MIT'
  s.metadata = {
    "changelog_uri" => "https://github.com/skaes/time_bandits/blob/master/README.md#release-notes"
  }

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency("thread_variables")
  s.add_runtime_dependency("activesupport", [">= 5.2.0"])
end

