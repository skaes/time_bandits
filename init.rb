# this file gets only loaded for rails2
require 'time_bandits'
require 'time_bandits/monkey_patches/active_record_rails2'
require 'time_bandits/monkey_patches/action_controller_rails2'

ActionController::Base.send :include, ActionController::TimeBanditry

TimeBandits::TimeConsumers::GarbageCollection.heap_dumps_enabled = %w(production development).include?(RAILS_ENV)

# TimeBandits.add TimeBandits::TimeConsumers::Memcached if defined?(Memcached)
# TimeBandits.add TimeBandits::TimeConsumers::GarbageCollection.instance if GC.respond_to? :enable_stats
# TimeBandits.add TimeBandits::TimeConsumers::JMX.instance if defined? JRUBY_VERSION
