require 'active_support/core_ext'

module TimeBandits

  module TimeConsumers
    if defined?(Rails) && Rails::VERSION::STRING < "3.0"
      autoload :Database,          'time_bandits/time_consumers/database_rails2'
    else
      autoload :Database,          'time_bandits/time_consumers/database'
    end
    autoload :GarbageCollection, 'time_bandits/time_consumers/garbage_collection'
    autoload :JMX,               'time_bandits/time_consumers/jmx'
    autoload :MemCache,          'time_bandits/time_consumers/mem_cache'
    autoload :Memcached,         'time_bandits/time_consumers/memcached'
  end

  require 'time_bandits/railtie' if defined?(Rails) && Rails::VERSION::STRING >= "3.0"

  mattr_accessor :time_bandits
  self.time_bandits = []

  def self.add(bandit)
    self.time_bandits << bandit unless self.time_bandits.include?(bandit)
  end

  def self.reset
    time_bandits.each{|b| b.reset}
  end

  def self.consumed
    time_bandits.map{|b| b.consumed}.sum
  end

  def self.runtime
    time_bandits.map{|b| b.runtime}.join(", ")
  end

  def self.metrics
    metrics = {}
    time_bandits.each{|b| metrics.merge! b.metrics}
    metrics
  end

  def self.benchmark(title="Completed in", logger=Rails.logger)
    reset
    result = nil
    e = nil
    seconds = Benchmark.realtime do
      begin
        result = yield
      rescue Exception => e
        logger.error "Exception: #{e}"
      end
    end
    consumed # needs to be called for DB time consumer
    rc = e ? "500 Internal Server Error" : "200 OK"
    logger.info "#{title} #{sprintf("%.3f", seconds * 1000)}ms (#{runtime}) | #{rc}"
    raise e if e
    result
  end
end
