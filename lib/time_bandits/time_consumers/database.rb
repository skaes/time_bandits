# this consumer gets installed automatically by the plugin
# if this were not so
#
#   time_bandit TimeBandits::TimeConsumers::Database.new
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
        ActiveRecord::Base.connection.reset_query_cache_hits
        ActiveRecord::Base.connection.reset_call_count
        ActiveRecord::Base.connection.reset_runtime
        @call_count = 0
        @consumed = 0.0
        @query_cache_hits = 0
      end

      def consumed
        @query_cache_hits = ActiveRecord::Base.connection.reset_query_cache_hits
        @call_count += ActiveRecord::Base.connection.reset_call_count
        @consumed += ActiveRecord::Base.connection.reset_runtime
      end

      def runtime
        sprintf "DB: %.3f(%d,%d)", @consumed * 1000, @call_count, @query_cache_hits
      end
    end
  end
end
