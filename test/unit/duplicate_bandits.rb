require_relative '../test_helper'

class DuplicateBandits < Test::Unit::TestCase
  class FooConsumer < TimeBandits::TimeConsumers::BaseConsumer
    prefix :simple
    fields :time, :calls
    format "SimpleFoo: %.1fms(%d calls)", :time, :calls
  end

  class BarConsumer < TimeBandits::TimeConsumers::BaseConsumer
    prefix :simple
    fields :time, :calls
    format "SimpleBar: %.1fms(%d calls)", :time, :calls
  end

  def setup
    TimeBandits.time_bandits = []
    TimeBandits.add FooConsumer
    TimeBandits.add BarConsumer
    TimeBandits.reset
  end

  test "nothing measured" do
    assert_equal({
      :simple_time => 0,
      :simple_calls => 0
    }, TimeBandits.metrics)
  end

  test "only one consumer measured sth (the one)" do
    FooConsumer.instance.calls = 3
    FooConsumer.instance.time  = 0.123
    assert_equal({
      :simple_time => 0.123,
      :simple_calls => 3
    }, TimeBandits.metrics)
  end

  test "only one consumer measured sth (the other)" do
    BarConsumer.instance.calls = 2
    BarConsumer.instance.time  = 0.321
    assert_equal({
      :simple_time => 0.321,
      :simple_calls => 2
    }, TimeBandits.metrics)
  end

  test "both consumer measured sth" do
    FooConsumer.instance.calls = 3
    FooConsumer.instance.time  = 0.123
    BarConsumer.instance.calls = 2
    BarConsumer.instance.time  = 0.321
    assert_equal({
      :simple_time => 0.444,
      :simple_calls => 5
    }, TimeBandits.metrics)
  end
end
