# a time consumer implementation for garbage collection
module TimeBandits
  module TimeConsumers
    class GarbageCollection
      @@heap_dumps_enabled = false
      def self.heap_dumps_enabled=(v)
        @@heap_dumps_enabled = v
      end

      def initialize
        enable_stats
        reset
      end
      private :initialize

      def self.instance
        @instance ||= new
      end

      def enable_stats
        return unless GC.respond_to? :enable_stats
        GC.enable_stats
        if defined?(PhusionPassenger)
          PhusionPassenger.on_event(:starting_worker_process) do |forked|
            GC.enable_stats if forked
          end
        end
      end

      if GC.respond_to?(:collections)
        def _get_collections; GC.collections; end
      elsif GC.respond_to?(:count)
        def _get_collections; GC.count; end
      else
        def _get_collections; 0; end
      end

      if ObjectSpace.respond_to?(:allocated_objects)
        def _get_allocated_objects; ObjectSpace.allocated_objects; end
      elsif GC.respond_to?(:stat) && RUBY_VERSION >= "2.1.0"
        def _get_allocated_objects; GC.stat(:total_allocated_object); end
      else
        def _get_allocated_objects; 0; end
      end

      if GC.respond_to?(:allocated_size)
        def _get_allocated_size; GC.allocated_size; end
      elsif GC.respond_to?(:total_malloced_bytes)
        def _get_allocated_size; GC.total_malloced_bytes; end
      else
        def _get_allocated_size; 0; end
      end

      if GC.respond_to? :heap_slots

        def reset
          @consumed = GC.time
          @collections = _get_collections
          @allocated_objects = _get_allocated_objects
          @allocated_size = _get_allocated_size
          @heap_slots = GC.heap_slots
        end

      else

        def reset
          @consumed = GC.time
          @collections = _get_collections
        end

      end

      def consumed
        0.0
      end

      def consumed_gc_time # ms
        (GC.time - @consumed).to_f / 1000
      end

      def collections
        _get_collections - @collections
      end

      if GC.respond_to? :heap_slots

        def allocated_objects
          _get_allocated_objects - @allocated_objects
        end

        def allocated_size
          _get_allocated_size - @allocated_size
        end

        def heap_growth
          GC.heap_slots - @heap_slots
        end

        if GC.respond_to? :heap_slots_live_after_last_gc
          def live_data_set_size; GC.heap_slots_live_after_last_gc; end
        else
          def live_data_set_size; 0; end
        end

        GCFORMAT = "GC: %.3f(%d) | HP: %d(%d,%d,%d,%d)"

        def runtime
          heap_slots = GC.heap_slots
          heap_growth = self.heap_growth
          allocated_objects = self.allocated_objects
          allocated_size = self.allocated_size
          GCHacks.heap_dump if heap_growth > 0 && @@heap_dumps_enabled && defined?(GCHacks)
          GCFORMAT % [consumed_gc_time, collections, heap_growth, heap_slots, allocated_objects, allocated_size, live_data_set_size]
        end

        def metrics
          {
            :gc_time => consumed_gc_time,
            :gc_calls => collections,
            :heap_growth => heap_growth,
            :heap_size => GC.heap_slots,
            :allocated_objects => allocated_objects,
            :allocated_bytes => allocated_size,
            :live_data_set_size => live_data_set_size
          }
        end

      else

        def runtime
          "GC: %.3f(%d)" % [consumed_gc_time, collections]
        end

        def metrics
          {
            :gc_time => consumed_gc_time,
            :gc_calls => collections
          }
        end

      end
    end
  end
end
