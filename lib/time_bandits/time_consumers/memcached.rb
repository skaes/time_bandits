# a time consumer implementation for memchached
# install into application_controller.rb with the line
#
#   time_bandit TimeBandits::TimeConsumers::Memcached
#
require 'time_bandits/monkey_patches/memcached'

module TimeBandits
  module TimeConsumers
    class Memcached < BaseConsumer
      prefix :memcache
      fields :time, :calls, :misses, :reads, :writes
      format "MC: %.3f(%dr,%dm,%dw,%dc)", :time, :reads, :misses, :writes, :calls

      class Subscriber < ActiveSupport::LogSubscriber
        def get(event)
          i = Memcached.instance
          i.time += event.duration
          i.calls += 1
          payload = event.payload
          i.reads += payload[:reads]
          i.misses += payload[:misses]
        end
        def set(event)
          i = Memcached.instance
          i.time += event.duration
          i.calls += 1
          i.writes += 1
        end
      end
      Subscriber.attach_to :memcached
    end
  end
end
