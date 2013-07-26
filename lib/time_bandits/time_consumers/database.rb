# this consumer gets installed automatically by the plugin
# if this were not so
#
#   TimeBandit.add TimeBandits::TimeConsumers::Database
#
# would do the job

module TimeBandits
  module TimeConsumers
    # provide a time consumer interface to ActiveRecord
    class Database < TimeBandits::TimeConsumers::BaseConsumer
      prefix :db
      fields :time, :calls, :sql_query_cache_hits
      format "ActiveRecord: %.3fms(%dq,%dh)", :time, :calls, :sql_query_cache_hits

      def reset
        reset_stats
        super
      end

      def consumed
        time, calls, hits = reset_stats
        i = Database.instance
        i.sql_query_cache_hits += hits
        i.calls += calls
        i.time += time
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
