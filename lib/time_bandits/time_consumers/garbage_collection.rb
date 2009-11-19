# a time consumer implementation for garbage collection
module TimeBandits
  module TimeConsumers
    class GarbageCollection
      @@heap_dumps_enabled = false
      def self.heap_dumps_enabled=(v)
        @@heap_dumps_enabled = v
      end

      def initialize
        GC.enable_stats
        reset
      end
      private :initialize

      def self.instance
        @instance ||= new
      end

      if GC.respond_to? :heap_slots

        def reset
          @consumed = GC.time
          @collections = GC.collections
          @allocated_objects = ObjectSpace.allocated_objects
          @allocated_size = GC.allocated_size
          @heap_slots = GC.heap_slots
        end

      else

        def reset
          @consumed = GC.time
          @collections = GC.collections
        end

      end

      def consumed
        0.0
      end

      def consumed_gc_time
        (GC.time - @consumed).to_f / 1_000_000
      end

      def collections
        GC.collections - @collections
      end

      if GC.respond_to? :heap_slots

        def allocated_objects
          ObjectSpace.allocated_objects - @allocated_objects
        end

        def allocated_size
          GC.allocated_size - @allocated_size
        end

        def heap_growth
          GC.heap_slots - @heap_slots
        end

        def runtime
          heap_slots = GC.heap_slots
          heap_growth = self.heap_growth
          allocated_objects = self.allocated_objects
          allocated_size = self.allocated_size
          GCHacks.heap_dump if heap_growth > 0 && @@heap_dumps_enabled
          "GC: %.3f(%d), HP: %d(%d,%d,%d)" % [consumed_gc_time * 1000, collections, heap_growth, heap_slots, allocated_objects, allocated_size]
        end

      else

        def runtime
          "GC: %.3f(%d)" % [consumed_gc_time * 1000, collections]
        end

      end
    end
  end
end
