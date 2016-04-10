require_relative '../test_helper'

class NoTimeBanditsTest < Test::Unit::TestCase
  def setup
    TimeBandits.time_bandits = []
  end

  test "getting list of all time bandits" do
    assert_equal [], TimeBandits.time_bandits
    test_clean_state
  end

  test "reset" do
    assert_nothing_raised { TimeBandits.reset }
    test_clean_state
  end

  test "benchmarking" do
    logger = mock("logger")
    logger.expects(:info)
    TimeBandits.benchmark("foo", logger) { }
    test_clean_state
  end

  private
  def test_clean_state
    assert_equal Hash.new, TimeBandits.metrics
    assert_equal 0, TimeBandits.consumed
    assert_equal 0, TimeBandits.current_runtime
    assert_equal "", TimeBandits.runtime
  end
end

class DummyConsumerTest < Test::Unit::TestCase
  module DummyConsumer
    extend self
    def consumed; 1; end
    def current_runtime; 1; end
    def runtime; "Dummy: 0ms"; end
    def metrics; {:dummy_time => 1, :dummy_calls => 1}; end
    def reset; end
  end

  def setup
    TimeBandits.time_bandits = []
    TimeBandits.add DummyConsumer
  end

  test "getting list of all time bandits" do
    assert_equal [DummyConsumer], TimeBandits.time_bandits
  end

  test "adding consumer a second time does not change the list of time bandits" do
    TimeBandits.add DummyConsumer
    assert_equal [DummyConsumer], TimeBandits.time_bandits
  end

  test "reset" do
    assert_nothing_raised { TimeBandits.reset }
  end

  test "consumed" do
    assert_equal 1, TimeBandits.consumed
  end

  test "current_runtime" do
    assert_equal 1, TimeBandits.current_runtime
  end

  test "current_runtime without DummyConsumer" do
    assert_equal 0, TimeBandits.current_runtime(DummyConsumer)
  end

  test "getting metrics" do
    assert_equal({:dummy_time => 1, :dummy_calls => 1}, TimeBandits.metrics)
  end
end
