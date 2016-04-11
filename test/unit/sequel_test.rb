require_relative '../test_helper'
require 'sequel'

class SequelTest < Test::Unit::TestCase
  def setup
    TimeBandits.time_bandits = []
    TimeBandits.add TimeBandits::TimeConsumers::Sequel
    TimeBandits.reset
  end

  test "getting metrics" do
    nothing_measured = {
      :db_time => 0,
      :db_calls => 0
    }
    assert_equal nothing_measured, metrics
    assert_equal 0, TimeBandits.consumed
    assert_equal 0, TimeBandits.current_runtime
  end

  test "formatting" do
    bandit.calls = 3
    assert_equal "Sequel: 0.000ms(3q)", TimeBandits.runtime
  end

  test "metrics" do
    (1..4).each { sequel['SELECT 1'].all }

    assert_equal 6, metrics[:db_calls] # +2 for set wait_timeout and set SQL_AUTO_IS_NULL=0
    assert 0 < metrics[:db_time]
    assert_equal metrics[:db_time], TimeBandits.consumed
  end

  def sequel
    @sequel ||= Sequel.connect('mysql2://localhost:3601')
  end

  def metrics
    TimeBandits.metrics
  end

  def bandit
    TimeBandits::TimeConsumers::Sequel.instance
  end
end
