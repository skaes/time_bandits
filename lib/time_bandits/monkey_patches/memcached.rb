# Add this line to your ApplicationController (app/controllers/application_controller.rb)
# to enable logging for memcached:
# time_bandit TimeBandits::TimeConsumers::Memcached

require 'memcached'
raise "Memcached needs to be loaded before monkey patching it" unless defined?(Memcached)

class Memcached

  def self.reset_benchmarks
    @@cache_latency = 0.0
    @@cache_calls = 0
    @@cache_misses = 0
    @@cache_reads = 0
    @@cache_writes = 0
  end
  self.reset_benchmarks

  def self.get_benchmarks
    [@@cache_latency, @@cache_calls, @@cache_reads, @@cache_misses, @@cache_writes]
  end

  def self.cache_runtime
    sprintf "MC: %.3f(%dr,%dm,%dw,%dc)", @@cache_latency * 1000, @@cache_reads, @@cache_misses, @@cache_writes, @@cache_calls
  end

  def self.metrics
    {
      :memcache_time   => @@cache_latency * 1000,
      :memcache_calls  => @@cache_calls,
      :memcache_misses => @@cache_misses,
      :memcache_reads  => @@cache_reads,
      :memcache_writes => @@cache_writes
    }
  end

  def get_with_benchmark(key, marshal = true)
    @@cache_calls += 1
    if key.is_a?(Array)
      @@cache_reads += (num_keys = key.size)
      results = []
      @@cache_latency += Benchmark.realtime do
        begin
          results = get_without_benchmark(key, marshal)
        rescue Memcached::NotFound
        end
      end
      @@cache_misses += num_keys - results.size
      results
    else
      val = nil
      @@cache_reads += 1
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

  def set_with_benchmark(*args)
    @@cache_calls += 1
    @@cache_writes += 1
    result = nil
    exception = nil
    @@cache_latency += Benchmark.realtime do
      begin
        set_without_benchmark(*args)
      rescue Exception => exception
      end
    end
    raise exception if exception
    result
  end
  alias_method :set_without_benchmark, :set
  alias_method :set, :set_with_benchmark

end

