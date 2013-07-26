# a time consumer implementation for memchache
# install into application_controller.rb with the line
#
#   time_bandit TimeBandits::TimeConsumers::MemCache
#
require 'time_bandits/monkey_patches/memcache-client'

module TimeBandits
  module TimeConsumers
    class Memcache < BaseConsumer
      prefix :memcache
      fields :time, :calls, :misses
      format "MC: %.3f(%dr,%dm)", :time, :calls, :misses

      class Subscriber < ActiveSupport::LogSubscriber
        def get(event)
          i = Memcache.instance
          i.time += event.duration
          i.calls += 1
          i.misses += event.payload[:misses]
        end
      end
      Subscriber.attach_to :memcache
    end
  end
end
