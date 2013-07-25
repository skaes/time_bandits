require_relative '../test_helper'
require 'active_support/notifications'
require 'active_support/log_subscriber'
require 'thread_variables/access'

class ActiveSupportNotificationsTest < Test::Unit::TestCase
  module SimpleConsumer
    extend self
    def time
      Thread.current.locals[:simple_time] || 0
    end
    def time=(v)
      Thread.current.locals[:simple_time] = v
    end
    def calls
      Thread.current.locals[:simple_calls] || 0
    end
    def calls=(v)
      Thread.current.locals[:simple_calls] = v
    end

    def reset
      self.time = 0
      self.calls = 0
    end
    reset
    def metrics
      {:simple_time => time, :simple_calls => calls}
    end
    def consumed
      time
    end
    def runtime
      "Simple: %.1fms (%d calls)" % [time, calls]
    end
    def add_stats(time, calls)
      self.time += time
      self.calls += calls
    end
  end

  class SimpleNotificationSubscriber < ActiveSupport::LogSubscriber
    # need a logger, otherwise work will never be called
    def logger
      @logger ||= Logger.new(STDOUT)
    end
    def work(event)
      SimpleConsumer.add_stats(event.duration, 1)
    end
  end
  SimpleNotificationSubscriber.attach_to :simple

  def setup
    TimeBandits.time_bandits = []
    TimeBandits.add SimpleConsumer
    TimeBandits.reset
  end

  test "getting metrics" do
    assert_equal({:simple_calls => 0, :simple_time => 0}, TimeBandits.metrics)
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
    ActiveSupport::Notifications.instrument("work.simple") do
      sleep 0.1
    end
  end
  def check_work
    m = TimeBandits.metrics
    assert_equal 1, m[:simple_calls]
    assert 100 < m[:simple_time]
    assert 150 > m[:simple_time]
  end
end
