require 'minitest'
require 'mocha/minitest'
require 'minitest/pride'
require 'minitest/autorun'

require 'active_support/testing/declarative'
module Test
  module Unit
    class TestCase < Minitest::Test
      extend ActiveSupport::Testing::Declarative
      def assert_nothing_raised(*)
        yield
      end
    end
  end
end

require_relative '../lib/time_bandits'
require "byebug"

ActiveSupport::LogSubscriber.logger =::Logger.new("/dev/null")

# fake Rails
module Rails
  extend self
  ActiveSupport::Cache.format_version = 7.1 if Gem::Version.new(ActiveSupport::VERSION::STRING) >= Gem::Version.new("7.1.0")
  def cache
    @cache ||= ActiveSupport::Cache.lookup_store(:mem_cache_store)
  end
  def env
    "test"
  end
end
