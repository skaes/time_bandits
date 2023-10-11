require_relative '../test_helper'
require 'active_record'
require 'time_bandits/monkey_patches/active_record'

class DatabaseTest < Test::Unit::TestCase

  def setup
    TimeBandits.time_bandits = []
    TimeBandits.add TimeBandits::TimeConsumers::Database
    TimeBandits.reset
    @old_logger = ActiveRecord::Base.logger
    ActiveRecord::Base.logger = Logger.new($stdout)
    ActiveRecord::Base.logger.level = Logger::DEBUG

    ActiveRecord::Base.establish_connection(
      adapter:  "mysql2",
      username: "root",
      encoding: "utf8",
      host: ENV['MYSQL_HOST'] || "127.0.0.1",
      port: (ENV['MYSQL_PORT'] || 3601).to_i
    )
  end

  def teardown
    ActiveRecord::Base.logger = @old_logger
  end

  test "getting metrics" do
    nothing_measured = {
      :db_time => 0,
      :db_calls => 0,
      :db_sql_query_cache_hits => 0
    }
    assert_equal nothing_measured, TimeBandits.metrics
    assert_equal 0, TimeBandits.consumed
    assert_equal 0, TimeBandits.current_runtime
  end

  test "formatting" do
    metrics_store.runtime += 1.234
    metrics_store.call_count += 3
    metrics_store.query_cache_hits += 1
    TimeBandits.consumed
    assert_equal "ActiveRecord: 1.234ms(3q,1h)", TimeBandits.runtime
  end

  test "accessing current runtime" do
    metrics_store.runtime += 1.234
    assert_equal 1.234, TimeBandits.consumed
    assert_equal 0, metrics_store.runtime
    metrics_store.runtime += 4.0
    assert_equal 5.234, bandit.current_runtime
    assert_equal "ActiveRecord: 1.234ms(0q,0h)", TimeBandits.runtime
  end

  test "sql can be executed" do
    event = mock('event')
    event.stubs(:payload).returns({name: "MURKS", sql: "SELECT 1"})
    event.stubs(:duration).returns(0.1)
    ActiveRecord::Base.logger.expects(:debug)
    assert_nil log_subscriber.new.sql(event)
  end

  test "instrumentation records runtimes at log level debug" do
    ActiveRecord::Base.logger.stubs(:debug)
    ActiveRecord::Base.connection.execute "SELECT 1"
    bandit.consumed
    assert(bandit.current_runtime > 0)
    # 2 calls, because one configures the connection
    assert_equal 2, bandit.calls
    assert_equal 0, bandit.sql_query_cache_hits
  end

  test "instrumentation records runtimes at log level error" do
    skip if Gem::Version.new(ActiveRecord::VERSION::STRING) < Gem::Version.new("7.1.0")
    ActiveRecord::Base.logger.level = Logger::ERROR
    ActiveRecord::LogSubscriber.expects(:sql).never
    ActiveRecord::Base.connection.execute "SELECT 1"
    bandit.consumed
    assert(bandit.current_runtime > 0)
    # 2 calls, because one configures the connection
    assert_equal 2, bandit.calls
    assert_equal 0, bandit.sql_query_cache_hits
  end

  private

  def bandit
    TimeBandits::TimeConsumers::Database.instance
  end

  def metrics_store
    TimeBandits::TimeConsumers::Database.metrics_store
  end

  def log_subscriber
    ActiveRecord::LogSubscriber
  end
end
