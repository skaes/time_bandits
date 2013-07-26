require_relative '../test_helper'
require 'active_support/notifications'
require 'active_support/log_subscriber'
require 'thread_variables/access'

class ActiveSupportNotificationsTest < Test::Unit::TestCase
  class SimpleConsumer < TimeBandits::TimeConsumers::BaseConsumer
    prefix :simple
    fields :time, :calls
    format "Simple: %.1fms(%d calls)", :time, :calls

    class Subscriber < ActiveSupport::LogSubscriber
      def work(event)
        i = SimpleConsumer.instance
        i.time += event.duration
        i.calls += 1
      end
    end
    Subscriber.attach_to :simple
  end

  def setup
    TimeBandits.time_bandits = []
    TimeBandits.add SimpleConsumer
    TimeBandits.reset
  end

  test "getting metrics" do
    assert_equal({:simple_calls => 0, :simple_time => 0}, TimeBandits.metrics)
  end

  test "formatting" do
    assert_equal "Simple: 0.0ms(0 calls)", TimeBandits.runtime
  end

  test "foreground work gets accounted for in milliseconds" do
    work
    check_work
  end

  test "background work is ignored" do
    Thread.new do
      work
      check_work
    end.join
    m = TimeBandits.metrics
    assert_equal 0, m[:simple_calls]
    assert_equal 0, m[:simple_time]
  end

  private
  def work
    2.times do
      ActiveSupport::Notifications.instrument("work.simple") { sleep 0.1 }
    end
  end
  def check_work
    m = TimeBandits.metrics
    assert_equal 2, m[:simple_calls]
    assert 200 < m[:simple_time]
    assert 300 > m[:simple_time]
    assert_equal m[:simple_time], TimeBandits.consumed
  end
end
