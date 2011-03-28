require 'time_bandits'
require 'jmx' if defined? JRUBY_VERSION

ActiveSupport.on_load(:action_controller) do
  require 'time_bandits/monkey_patches/rails_rack_logger'
  require 'time_bandits/monkey_patches/action_controller'
  include ActionController::TimeBanditry
end

ActiveSupport.on_load(:active_record) do
  require 'time_bandits/monkey_patches/activerecord_adapter'
  TimeBandits.add TimeBandits::TimeConsumers::Database.instance
end

TimeBandits::TimeConsumers::GarbageCollection.heap_dumps_enabled = %w(production development).include?(Rails.env)

TimeBandits.add TimeBandits::TimeConsumers::Memcached if defined?(Memcached)
TimeBandits.add TimeBandits::TimeConsumers::GarbageCollection.instance if GC.respond_to? :enable_stats
TimeBandits.add TimeBandits::TimeConsumers::JMX.instance if defined? JRUBY_VERSION
