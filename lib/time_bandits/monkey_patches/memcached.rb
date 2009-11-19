# Add this line to your ApplicationController (app/controllers/application_controller.rb)
# to enable logging for memcached:
# time_bandit TimeBandits::TimeConsumers::Memcached

require 'memcached'
raise "Memcached needs to be loaded before monkey patching it" unless defined?(Memcached)

class Memcached
  @@cache_latency = 0.0
  @@cache_touches = 0
  @@cache_misses = 0

  def self.reset_benchmarks
    @@cache_latency = 0.0
    @@cache_touches = 0
    @@cache_misses = 0
  end

  def self.get_benchmarks
    [@@cache_latency, @@cache_touches, @@cache_misses]
  end

  def self.cache_runtime
    sprintf "MC: %.3f(%dr,%dm)", @@cache_latency * 1000, @@cache_touches, @@cache_misses
  end

  def get_with_benchmark(key, marshal = true)
    @@cache_touches += 1
    if key.is_a?(Array)
      results = []
      @@cache_latency += Benchmark.realtime do
        begin
          results = get_without_benchmark(key, marshal)
        rescue Memcached::NotFound
        end
      end
      @@cache_misses += key.size - results.size
      results
    else
      val = nil
      @@cache_latency += Benchmark.realtime do
        begin
          val = get_without_benchmark(key, marshal)
        rescue Memcached::NotFound
        end
      end
      @@cache_misses += 1 if val.nil?
      val
    end
  end
  alias_method :get_without_benchmark, :get
  alias_method :get, :get_with_benchmark

end

