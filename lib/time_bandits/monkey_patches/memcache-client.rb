# Add this line to your ApplicationController (app/controllers/application.rb)
# to enable logging for memcache-client:
# time_bandit MemCache

require 'memcache'
raise "MemCache needs to be loaded before monkey patching it" unless defined?(MemCache)

class MemCache
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

  def get_with_benchmark(key, raw = false)
    val = nil
    @@cache_latency += Benchmark.realtime{ val=get_without_benchmark(key, raw) }
    @@cache_touches += 1
    @@cache_misses += 1 if val.nil?
    val
  end
  alias_method :get_without_benchmark, :get
  alias_method :get, :get_with_benchmark

  def get_multi_with_benchmark(*keys)
    results = nil
    @@cache_latency += Benchmark.realtime{ results=get_multi_without_benchmark(*keys) }
    @@cache_touches += 1
    @@cache_misses += keys.size - results.size
    results
  end
  alias_method :get_multi_without_benchmark, :get_multi
  alias_method :get_multi, :get_multi_with_benchmark

end

