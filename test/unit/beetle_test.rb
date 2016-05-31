require_relative '../test_helper'

require 'beetle'

class BeetleTest < Test::Unit::TestCase
  def setup
    TimeBandits.time_bandits = []
    TimeBandits.add TimeBandits::TimeConsumers::Beetle
    TimeBandits.reset
    @beetle = Beetle::Client.new
    @beetle.configure do
      message :foo
    end
    @bandit = TimeBandits::TimeConsumers::Beetle.instance
  end

  test "getting metrics" do
    nothing_measured = {
      :amqp_time => 0,
      :amqp_calls => 0
    }
    assert_equal nothing_measured, TimeBandits.metrics
    assert_equal 0, TimeBandits.consumed
    assert_equal 0, TimeBandits.current_runtime
  end

  test "formatting" do
    @bandit.calls = 3
    assert_equal "Beetle: 0.000(3)", TimeBandits.runtime
  end

  test "foreground work gets accounted for" do
    work
    check_work
  end

  test "background work is ignored" do
    Thread.new do
      work
      check_work
    end.join
    m = TimeBandits.metrics
    assert_equal 0, m[:amqp_calls]
    assert_equal 0, m[:amqp_time]
  end

  private

  def work
    TimeBandits.reset
    2.times do
      @beetle.publish("foo")
      @beetle.publish("foo")
    end
  end

  def check_work
    m = TimeBandits.metrics
    assert_equal 4, m[:amqp_calls]
    assert 0 < m[:amqp_time]
    assert_equal m[:amqp_time], TimeBandits.consumed
  end
end
