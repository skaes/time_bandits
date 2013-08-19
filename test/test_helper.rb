require 'test/unit'
require 'mocha/setup'
require 'active_support/testing/declarative'

require 'minitest/pride'

class Test::Unit::TestCase
  extend ActiveSupport::Testing::Declarative
end

require_relative '../lib/time_bandits'

ActiveSupport::LogSubscriber.class_eval do
  # need a logger, otherwise no data will be collected
  def logger
    @logger ||= ::Logger.new("/dev/null")
  end
end

# fake Rails
module Rails
  extend self
  module VERSION
    STRING = "4.0.0"
  end
  def cache
    @cache ||= ActiveSupport::Cache.lookup_store(:mem_cache_store)
  end
end
