module TimeBandits
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

  def self.benchmark(title="Completed in", logger=Rails.logger)
    reset
    result = nil
    seconds = Benchmark.realtime { result = yield }
    consumed # needs to be called for DB time consumer
    logger.info "#{title} #{sprintf("%.3f", seconds * 1000)}ms (#{runtime})"
    result
  end
end
