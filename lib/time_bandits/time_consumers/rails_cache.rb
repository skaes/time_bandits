module TimeBandits::TimeConsumers
  class RailsCache < BaseConsumer
    prefix :memcache
    fields :time, :calls, :misses, :reads, :writes
    format "MC: %.3f(%dr,%dm,%dw,%dc)", :time, :reads, :misses, :writes, :calls

    class Subscriber < ActiveSupport::LogSubscriber
      # cache events are: read write fetch_hit generate delete read_multi increment decrement clear
      def cache_read(event)
        i = RailsCache.instance
        i.reads += 1
        i.misses += 1 unless event.payload[:hit]
        cache(:read, i, event)
      end

      def cache_read_multi(event)
        i = RailsCache.instance
        i.reads += event.payload[:key].size
        cache(:read_multi, i, event)
      end

      def cache_write(event)
        i = RailsCache.instance
        i.writes += 1
        chache(:write, i, event)
      end

      private
      def cache(method, instance, event)
        instance.time += event.duration
        instance.calls += 1

        debug 'RailsCache %s: %s (%.3fms)' % [method, event.payload[:key].inspect, event.duration]
      end
    end
    Subscriber.attach_to :active_support
  end

end
