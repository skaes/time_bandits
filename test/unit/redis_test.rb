require_relative '../test_helper'

class RedisTest < Test::Unit::TestCase
  def setup
    TimeBandits.time_bandits = []
    TimeBandits.add TimeBandits::TimeConsumers::Redis
    TimeBandits.reset
    @redis = Redis.new
    @bandit = TimeBandits::TimeConsumers::Redis.instance
  end

  test "getting metrics" do
    nothing_measured = {
      :redis_time => 0,
      :redis_calls => 0
    }
    assert_equal nothing_measured, TimeBandits.metrics
  end

  test "formatting" do
    @bandit.calls = 3
    assert_equal "Redis: 0.000(3)", TimeBandits.runtime
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
    assert_equal 0, m[:redis_calls]
    assert_equal 0, m[:redis_time]
  end

  test "counts pipelined calls as single call" do
    pipelined_work
    m = TimeBandits.metrics
    assert_equal 1, m[:redis_calls]
  end

  test "counts multi calls as single call" do
    pipelined_work(:multi)
    m = TimeBandits.metrics
    assert_equal 1, m[:redis_calls]
  end

  private
  def pipelined_work(type = :pipelined)
    TimeBandits.reset
    @redis.send(type) do
      @redis.get("foo")
      @redis.set("bar", 1)
      @redis.hgetall("baz")
    end
  end

  def work
    TimeBandits.reset
    2.times do
      @redis.get("foo")
      @redis.set("bar", 1)
    end
  end
  def check_work
    m = TimeBandits.metrics
    assert_equal 4, m[:redis_calls]
    assert 0 < m[:redis_time]
    assert_equal m[:redis_time], TimeBandits.consumed
  end
end
