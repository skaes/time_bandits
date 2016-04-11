require_relative '../test_helper'
require 'active_record'
require 'time_bandits/monkey_patches/active_record'

class DatabaseTest < Test::Unit::TestCase
  def setup
    TimeBandits.time_bandits = []
    TimeBandits.add TimeBandits::TimeConsumers::Database
    TimeBandits.reset
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
    log_subscriber.runtime += 1.234
    log_subscriber.call_count += 3
    log_subscriber.query_cache_hits += 1
    TimeBandits.consumed
    assert_equal "ActiveRecord: 1.234ms(3q,1h)", TimeBandits.runtime
  end

  test "accessing current runtime" do
    log_subscriber.runtime += 1.234
    assert_equal 1.234, TimeBandits.consumed
    assert_equal 0, log_subscriber.runtime
    log_subscriber.runtime += 4.0
    assert_equal 5.234, bandit.current_runtime
    assert_equal "ActiveRecord: 1.234ms(0q,0h)", TimeBandits.runtime
  end

  private

  def bandit
    TimeBandits::TimeConsumers::Database.instance
  end

  def log_subscriber
    ActiveRecord::LogSubscriber
  end
end
