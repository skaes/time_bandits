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

      class << self
        if Gem::Version.new(ActiveRecord::VERSION::STRING) >= Gem::Version.new("7.1.0")
          def metrics_store
            ActiveRecord::RuntimeRegistry
          end
        else
          def metrics_store
            ActiveRecord::LogSubscriber
          end
        end
      end

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

      def current_runtime
        Database.instance.time + self.class.metrics_store.runtime
      end

      private

      def reset_stats
        s = self.class.metrics_store
        hits  = s.reset_query_cache_hits
        calls = s.reset_call_count
        time  = s.reset_runtime
        [time, calls, hits]
      end
    end
  end
end
