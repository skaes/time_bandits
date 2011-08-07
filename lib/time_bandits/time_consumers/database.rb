# this consumer gets installed automatically by the plugin
# if this were not so
#
#   TimeBandit.add TimeBandits::TimeConsumers::Database
#
# would do the job

module TimeBandits
  module TimeConsumers
    # provide a time consumer interface to ActiveRecord
    module Database
      extend self

      def info
        Thread.current[:time_bandits_database_info] ||= [0.0, 0, 0]
      end

      def info=(info)
        Thread.current[:time_bandits_database_info] = info
      end

      def reset
        reset_stats
        self.info = [0.0, 0, 0]
      end

      def consumed
        time, calls, hits = reset_stats
        i = self.info
        i[2] += hits
        i[1] += calls
        i[0] += time
      end

      def runtime
        sprintf "ActiveRecord: %.3fms(%dq,%dh)", *info
      end

      def metrics
        {
          :db_calls => @call_count,
          :db_sql_query_cache_hits  => @query_cache_hits,
          :db_time => @consumed * 1000
        }
      end

      private

      def reset_stats
        s = ActiveRecord::LogSubscriber
        hits  = s.reset_query_cache_hits
        calls = s.reset_call_count
        time  = s.reset_runtime
        [time, calls, hits]
      end
    end
  end
end
