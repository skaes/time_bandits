require_relative '../test_helper'

class MemcachedTest < Test::Unit::TestCase
  def setup
    TimeBandits.time_bandits = []
    TimeBandits.add TimeBandits::TimeConsumers::Memcached
    TimeBandits.reset
    @cache = Memcached.new
  end

  test "getting metrics" do
    nothing_measured = {
      :memcache_time=>0,
      :memcache_calls=>0,
      :memcache_misses=>0,
      :memcache_reads=>0,
      :memcache_writes=>0
    }
    assert_equal nothing_measured, TimeBandits.metrics
  end

  test "formatting" do
    assert_equal "MC: 0.000(0r,0m,0w,0c)", TimeBandits.runtime
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
    assert_equal 0, m[:memcache_calls]
    assert_equal 0, m[:memcache_reads]
    assert_equal 0, m[:memcache_misses]
    assert_equal 0, m[:memcache_writes]
    assert_equal 0, m[:memcache_time]
  end

  private
  def work
    2.times do
      @cache.get("foo")
      @cache.set("bar", 1)
    end
  end
  def check_work
    m = TimeBandits.metrics
    assert_equal 4, m[:memcache_calls]
    assert_equal 2, m[:memcache_reads]
    assert_equal 2, m[:memcache_misses]
    assert_equal 2, m[:memcache_writes]
    assert 0 < m[:memcache_time]
    assert_equal m[:memcache_time], TimeBandits.consumed
  end
end
