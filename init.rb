require 'time_bandits'
require 'jmx' if defined? JRUBY_VERSION

ActionController::Base.send :include, ActionController::TimeBanditry

TimeBandits::TimeConsumers::GarbageCollection.heap_dumps_enabled = %w(production development).include?(RAILS_ENV)

TimeBandits.add TimeBandits::TimeConsumers::Memcached if defined?(Memcached)
TimeBandits.add TimeBandits::TimeConsumers::GarbageCollection.instance if GC.respond_to? :enable_stats
TimeBandits.add TimeBandits::TimeConsumers::JMX.instance if defined? JRUBY_VERSION
