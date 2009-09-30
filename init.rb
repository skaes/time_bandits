require 'time_bandits'

ActionController::Base.send :include, ActionController::TimeBanditry

TimeBandits::TimeConsumers::GarbageCollection.heap_dumps_enabled = %w(production development).include?(RAILS_ENV)
