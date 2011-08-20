# Database time consumer for Rails2. You need to add it via
#
# TimeBandits.add TimeBandits::TimeConsumers::Database.instance
#

module TimeBandits
  module TimeConsumers
    # provide a time consumer interface to ActiveRecord for perform_action_with_benchmark and render_with_benchmark
    class Database
      def initialize
        @consumed = 0.0
        @call_count = 0
        @query_cache_hits = 0
      end
      private :initialize

      def self.instance
        @instance ||= new
      end

      def reset
        reset_stats
        @call_count = 0
        @consumed = 0.0
        @query_cache_hits = 0
      end

      def consumed
        hits, calls, time = reset_stats
        @query_cache_hits += hits
        @call_count += calls
        @consumed += time
      end

      def runtime
        sprintf "DB: %.3f(%d,%d)", @consumed * 1000, @call_count, @query_cache_hits
      end

      def metrics
        {
          :db_calls => @call_count,
          :db_sql_query_cache_hits  => @query_cache_hits,
          :db_time => @consumed * 1000
        }
      end

      private
      def all_connections
        ActiveRecord::Base.connection_handler.connection_pools.values.map{|pool| pool.connections}.flatten
      end

      def reset_stats
        connections = all_connections
        hits  = connections.map{|c| c.reset_query_cache_hits}.sum
        calls = connections.map{|c| c.reset_call_count}.sum
        time  = connections.map{|c| c.reset_runtime}.sum
        [hits, calls, time]
      end
    end
  end
end
