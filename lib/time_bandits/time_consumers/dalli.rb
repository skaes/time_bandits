module TimeBandits::TimeConsumers
  class Dalli < BaseConsumer
    prefix :memcache
    fields :time, :calls, :misses, :reads, :writes
    format "DALLI: %.3f(%dr,%dm,%dw,%dc)", :time, :reads, :misses, :writes, :calls

    class Subscriber < ActiveSupport::LogSubscriber
      # cache events are: read write fetch_hit generate delete read_multi increment decrement clear
      def cache_read(event)
        i = cache(event)
        i.reads += 1
        i.misses += 1 unless event.payload[:hit]
      end

      def cache_read_multi(event)
        i = cache(event)
        i.reads += event.payload[:key].size
      end

      def cache_write(event)
        i = cache(event)
        i.writes += 1
      end

      def cache_increment(event)
        i = cache(event)
        i.writes += 1
      end

      def cache_decrement(event)
        i = cache(event)
        i.writes += 1
      end

      def cache_delete(event)
        i = cache(event)
        i.writes += 1
      end

      private
      def cache(event)
        i = Dalli.instance
        i.time += event.duration
        i.calls += 1
        i
      end
    end
    Subscriber.attach_to :active_support
  end

end
