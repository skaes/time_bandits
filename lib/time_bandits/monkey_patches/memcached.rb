# Add this line to your ApplicationController (app/controllers/application_controller.rb)
# to enable logging for memcached:
# time_bandit TimeBandits::TimeConsumers::Memcached

require 'memcached'
raise "Memcached needs to be loaded before monkey patching it" unless defined?(Memcached)

class Memcached
  def get_with_benchmark(key, marshal = true)
    ActiveSupport::Notifications.instrument("get.memcached") do |payload|
      if key.is_a?(Array)
        payload[:reads] = (num_keys = key.size)
        results = []
        begin
          results = get_without_benchmark(key, marshal)
        rescue Memcached::NotFound
        end
        payload[:misses] = num_keys - results.size
        results
      else
        val = nil
        payload[:reads] = 1
        begin
          val = get_without_benchmark(key, marshal)
        rescue Memcached::NotFound
        end
        payload[:misses] = val.nil? ? 1 : 0
        val
      end
    end
  end
  alias_method :get_without_benchmark, :get
  alias_method :get, :get_with_benchmark

  def set_with_benchmark(*args)
    ActiveSupport::Notifications.instrument("set.memcached") do
      set_without_benchmark(*args)
    end
  end
  alias_method :set_without_benchmark, :set
  alias_method :set, :set_with_benchmark

end
