# Add this line to your ApplicationController (app/controllers/application.rb)
# to enable logging for memcache-client:
# time_bandit MemCache

require 'memcache'
raise "MemCache needs to be loaded before monkey patching it" unless defined?(MemCache)

class MemCache

  def get_with_benchmark(key, raw = false)
    ActiveSupport::Notifications.instrument("get.memcache") do |payload|
      val = get_without_benchmark(key, raw)
      payload[:misses] = val.nil? ? 1 : 0
      val
    end
  end
  alias_method :get_without_benchmark, :get
  alias_method :get, :get_with_benchmark

  def get_multi_with_benchmark(*keys)
    ActiveSupport::Notifications.instrument("get.memcache") do |payload|
      results = get_multi_without_benchmark(*keys)
       payload[:misses] = keys.size - results.size
      results
    end
  end
  alias_method :get_multi_without_benchmark, :get_multi
  alias_method :get_multi, :get_multi_with_benchmark

end

