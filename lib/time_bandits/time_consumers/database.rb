# this consumer gets installed automatically by the plugin
# if this were not so
#
#   TimeBandit.add TimeBandits::TimeConsumers::Database.new
#
# would do the job

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
        sprintf "ActiveRecord: %.1fms(%d queries, %d cachehits)", @consumed, @call_count, @query_cache_hits
      end

      private

      def reset_stats
        s = ActiveRecord::LogSubscriber
        hits  = s.reset_query_cache_hits
        calls = s.reset_call_count
        time  = s.reset_runtime
        [hits, calls, time]
      end
    end
  end
end
