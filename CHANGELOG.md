# CHANGELOG

## 0.13.0
* Support redis 5.0.

## Version 0.12.7
* logging start time requires a real time, not a monotonic clock

## Version 0.12.6
* use ruby 3.1.1 in GitHub actions
* updated appraisals
* restrict Redis gem to a version before 5.0 until 5.x has become
  stable
* use monotonic clocks for time measurements

## Version 0.12.5
* use GC.stat(:malloc_increase_bytes) to measure allocated bytes as fallback
* support ruby 3.1.0 GC.total_time
* ruby 3.1.0 needs rails 7.0.1 to run the tests
* include ruby-3.1.0 on GitHub actions

## Version 0.12.4
* rails 7.0.0 compatibility
* only test Rails 3.0.0 with Ruby >= 2.7.0
* updated Appraisals
* use safe ruby version to run tests on GitHub
* switched to GitHub actions (#19)
* try to fix travis
* updated appraisals
* remove gemfiles created by appraisals and git ignore them

## Version 0.12.3
* relax minitest dependency
* suppress Ruby 2.7 warnings in action controller tests
* updated test container versions

## Version 0.12.2
* fixed that completed line was logged twice in Rails test environment
* split license into separate file
* added travis badge

## Version 0.12.1
* install GC time bandit automatically inRails applications
* only load railtie if class Rails::Railtie is defined

## Version 0.12.0
* removed leftover from old Rails plugin times
* don't need sudo on travis
* Merge pull request #15 from toy/patch-1
* try to fix travis build
* doc rephrasing
* updated README
* relax active support version requirement to 5.2.0
* updated travis build matrix
* dropped support for old rails and ruby versions
* silence ruby warnings
* updated docker images
* require at least version 5.2.4.3 for activesupport
* updated appraisals to only test supported Rails versions
* damn travis
* travis fu
* updated ruby versions
* trying to fix travis

## Version 0.11.0
* added and updated appraisals
* support rails 6
* Add changelog url to gemspec

## Version 0.10.12
* updated README
* also support future 5.0.x versions
* added appraisal for rails 5.0.7
* Merge pull request #14 from mediafinger/master
* Call type_casted_binds with only one argument in Rails 5.0.7

## Version 0.10.11
* prepare 0.10.11 release
* clarified how TimeBanditry gets activated in railtie
* test rails 5.2.0 compatibility
* Merge pull request #13 from sghosh23/update_rails_version_active_record_monkey_patch
* add rails version 5.2 to support active record monkey patch
* fix test failures on ActiveRecord 4.1.16
* reinstalled appraisals
* try to fix travis builds

## Version 0.10.10
* make sure sql method can be executed on logsubscriber
* updated appraisals

## Version 0.10.8
* added specialized activerecord logging for Rails >= 5.1.5

## Version 0.10.8
* rails has changed render_bind in 5.0.3
* updated README
* added rabbitmq as a service for travis
* added more rails versions to test against
* abort rake task when system calls fail
* fixed deprecation warning for ruby 2.4.1

## Version 0.10.7
* changed README format to markdown
* Merge pull request #11 from manveru/patch-1
* Adapt log_sql_statement for Rails 5.1
* changed travis command

## Version 0.10.6
* updated reales notes
* Merge pull request #9 from pinglamb/master
* added .travis.yml
* updated rails versions for appraisals

## Version 0.10.5
* make activerecord monkey patch available for rails 5.1

## Version 0.10.4
* protect against Rails 5 firing on_load handlers multiple times

## Version 0.10.3
* fixed activerecord logging monkey patch

## Version 0.10.2
* go back to using alias_method to enable testing with rspec

## Version 0.10.1
* fixed broken module.prepend

## Version 0.10.0
* updated release notes
* rebased on master
* added docker compose file to start redis, memcached, mysql and rabbitmq for testing
* added rails 5 to appraisals
* active record log subscriber changes to support rails 5
* checked and updated action controller hacks for rails 5
* rails 5 fixed the memcache store stats bug on fetch
* rails 5 deprecated alias_method_chain, used Module.prepend instead
* rails 5 deprecated string values for middlewares

## Version 0.9.2
* fixed sequel gem monkey patch
* I really hate the stupid decision by rake to force ruby -w on everyone
* updated rails versions in appraisals

## Version 0.9.1
* redis time consumer: make sure to log ASCII in debug mode

## Version 0.9.0
* added beetle time consumer
* Multiply 1000 to get the actual millisecond

## Version 0.8.1
* make sure every consumer has a current_runtime methods (duh)

## Version 0.8.0
* access current database runtime including not yet consumed time

## Version 0.7.4
* fixed that actions without render showed zero db time
* removed .lock files
* use appraisal for testing against multiple active support versions
* test with rails 4.2.4

## Version 0.7.3
* in rails 4.2 dalli is always instrumented
* monkey patches seem to be compatible with rails 4.2

## Version 0.7.2
* updated to support ruby 2.2.0

## Version 0.7.1
* style change
* updated README
* measure time and calls with sequel

## Version 0.7.0
* make the most out of an unpatched ruby

## Version 0.6.7
* fixed wrong nesting of public :sql

## Version 0.6.6
* fixed duplicate log lines for active record monkey patch and rails 4.1
* Count redis round trips not calls

## Version 0.6.5
* rails monkey patches are compatible with 4.1

## Version 0.6.4
* make sure not to call 'instrument=' if a rails 4 app uses :dalli_store instead of :mem_cache_store

## Version 0.6.3
* rails 3.2 columns don't understand binary?

## Version 0.6.2
* rails 4.0 updates to active_record monkey_patch

## Version 0.6.1
* support for ruby 2.1
* added test for GC time consumer

## Version 0.6.0
* updated README
* added tests for dalli and redis and new completed line behavior
* patched dalli consumer to work correctly with rails 4
* added redis time consumer
* don't include bandits in the the completed line which haven't measured anything

## Version 0.5.1
* added license information to gemspec

## Version 0.5.0
* ugly hack to ensure Completed lines are logged in the test environment
* reset time bandits before running controller tests
* renamed RailsCache consumer to dalli and rely on dalli for logging
* avoid calling logger in production
* install some gems for debugging
* updated README
* we're all milliseconds now
* we are thread safe now. lose the Rack::Lock middleware
* drop rails 2 support
* switch database consumer to use base_consumer
* added a general rails cache consumer (can be used to replace memcache consumers)
* make memcache consumers threadsafe
* use structs instead of hashes for counters
* more groundwork for thread safe time bandits
* added some tests

## Version 0.4.1
* added rake dev dependency
* we can't rely on Rack::Sendfile to be around

## Version 0.4.0
* rails 4.0 and tagged logging support

## Version 0.3.1
* need to call TimeBandits.consumed to get correct db time stats

## Version 0.3.0
* use thread local variables gem
* make use of thread_local_variable_access gem

## Version 0.2.2
* enable GC stats after passenger has forked a new worker process
* reset time bandits after rails initialization process has been completed

## Version 0.2.1
* use the correct rails version specific code to extract raw_payload

## Version 0.2.0
* basic rails 3.1 and 32. compatibility

## Version 0.1.4
* fixed bug related to mixing seconds and millicesonds

## Version 0.1.3
* db time is already measured in milliseconds

## Version 0.1.2
* the Rails 3 database consumer no longer uses instance variables for the statistics

## Version 0.1.1
* use own middlware logger and provide viewtime and action for logjam_agent

## Version 0.1.0
* ignore some files
* the version numbering is ridiculous
* add a bit of backtrace info
* removed last traces of agent suport
* provide metrics for rack middlewares
* metrics for rails2 database adapter
* improved metrics for memcached

## Version 0.0.9

* Relax Rails version check, still running fine on 2.3.14
* metrics agent support for rails 2

## Version 0.0.8
* gem compatibility for rails 2.3.x
* updated README

## Version 0.0.7
* git ignore the Gemfile.lock
* Assume status 500 in case of an exception being raised
* Fail gracefully if an exception occurs during before_dispatch

## Version 0.0.6
* updated gemspec to pin to the right branch on github

## Version 0.0.5
* prepare new version (now with activerecord support)
* updated readme
* database consumer is now thread safe
* initial version of ActiveRecord time consumer


## Version 0.0.4
* oh man. concentrate!

## Version 0.0.3
* oops

## Version 0.0.2
* refactored rack logger

## Version 0.0.1
* now a proper rails3 gem plugin
* removed log ouput
* don't install time bandits per default (app needs control over order of bandits in completed line)
* use the more accurate timing info
* Merge branch 'master' into rails3
* deleted unused file
* Merge branch 'master' into rails3
* checked in some xing modifications
* first stab at supporting rails3
* JRuby support for GC and memory statistics, using the jmx gem.
* during initialization, enable memcache and GC stats if they are available
* we are compatible to activerecord 2.3.5
* Merge branch 'master' of github.com:skaes/time_bandits
* time bandits registration interface changed and got a new method for creating log lines outside ActionController
* added Rakefile with rdoc task
* removed Rakefile
* initial import
