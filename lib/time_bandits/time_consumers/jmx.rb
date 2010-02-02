# a time consumer implementation for jruby, using jxm
#
# the gc counts and times reported are summed over all the garbage collectors
# heap_growth reflects changes in the committed size of the java heap
# heap_size is the committed size of the java heap
# allocated_size reflects changes in the active (used) part of the java heap
# java non-heap memory is not reported

module TimeBandits
  module TimeConsumers
    class JMX
      def initialize
        @server = ::JMX::MBeanServer.new
        @memory_bean = @server["java.lang:type=Memory"]
        @collectors = @server.query_names "java.lang:type=GarbageCollector,*"
        reset
      end
      private :initialize

      def self.instance
        @instance ||= new
      end

      def consumed
        0.0
      end

      def gc_time
        @collectors.to_array.map {|gc| @server[gc].collection_time}.sum
      end
      
      def gc_collections
        @collectors.to_array.map {|gc| @server[gc].collection_count}.sum
      end

      def heap_size
        @memory_bean.heap_memory_usage.committed
      end
      
      def heap_usage
        @memory_bean.heap_memory_usage.used
      end

      def reset
        @consumed = gc_time
        @collections = gc_collections
        @heap_committed = heap_size
        @heap_used = heap_usage
      end
      
      def collections_delta
        gc_collections - @collections
      end

      def gc_time_delta
        (gc_time - @consumed).to_f
      end

      def heap_growth
        heap_size - @heap_committed
      end

      def usage_growth
        heap_usage - @heap_used
      end
      
      def allocated_objects
        0
      end

      def runtime
        "GC: %.3f(%d), HP: %d(%d,%d,%d)" % [gc_time_delta, collections_delta, heap_growth, heap_size, allocated_objects, usage_growth]
      end

    end
  end
end
