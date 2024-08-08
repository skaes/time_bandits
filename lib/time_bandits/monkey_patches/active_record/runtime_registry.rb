# This file monkey patches class ActiveRecord::RuntimeRegistry to
# additionally store call counts and cache hits and subscribes an
# event listener to manage those counters. It is used if the active
# record version is 7.1.0 or higher.

require "active_record/runtime_registry"

module ActiveRecord
  module RuntimeRegistry

    if respond_to?(:queries_count)
      alias_method :call_count, :queries_count
      alias_method :call_count=, :queries_count=
    else
      def self.call_count
        ActiveSupport::IsolatedExecutionState[:active_record_sql_call_count] ||= 0
      end

      def self.call_count=(value)
        ActiveSupport::IsolatedExecutionState[:active_record_sql_call_count] = value
      end
    end

    if respond_to?(:cached_queries_count)
      alias_method :query_cache_hits, :cached_queries_count
      alias_method :query_cache_hits=, :cached_queries_count=
    else
      def self.query_cache_hits
        ActiveSupport::IsolatedExecutionState[:active_record_sql_query_cache_hits] ||= 0
      end

      def self.query_cache_hits=(value)
        ActiveSupport::IsolatedExecutionState[:active_record_sql_query_cache_hits] = value
      end
     end

    if respond_to?(:reset_runtimes)
      alias_method :reset_runtime, :reset_runtimes
    else
      alias_method :reset_runtime, :reset
    end
    alias_method :runtime, :sql_runtime
    alias_method :runtime=, :sql_runtime=

    def self.reset_call_count
      calls = call_count
      self.call_count = 0
      calls
    end

    def self.reset_query_cache_hits
      hits = query_cache_hits
      self.query_cache_hits = 0
      hits
    end

  end
end


# Rails 7.2 already collects query counts and cache hits, so we no
# longer need our own event handler.
unless ActiveRecord::RuntimeRegistry.respond_to?(:queries_count)
  require "active_support/notifications"

  ActiveSupport::Notifications.monotonic_subscribe("sql.active_record") do |event|
    ActiveRecord::RuntimeRegistry.call_count += 1
    ActiveRecord::RuntimeRegistry.query_cache_hits += 1 if event.payload[:cached]
  end
end
