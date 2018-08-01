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
  s.add_runtime_dependency("activesupport", [">= 2.3.2"])

  s.add_development_dependency("ansi")
  s.add_development_dependency("appraisal")
  s.add_development_dependency("byebug")
  s.add_development_dependency("dalli")
  s.add_development_dependency("memcached", "~> 1.8.0")
  s.add_development_dependency("minitest", "~> 5.5")
  s.add_development_dependency("mocha")
  s.add_development_dependency("mysql2")
  s.add_development_dependency("rake", "~> 10.5.0")
  s.add_development_dependency("redis")
  s.add_development_dependency("sequel")
  s.add_development_dependency("activerecord")
  s.add_development_dependency("beetle", ">= 0.4.6")
end

