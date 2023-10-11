# This file monkey patches class ActiveRecord::RuntimeRegistry to
# additionally store call counts and cache hits and subscribes an
# event listener to manage those counters.

require "active_record/runtime_registry"

module ActiveRecord
  module RuntimeRegistry

    def self.call_count
      ActiveSupport::IsolatedExecutionState[:active_record_sql_call_count] ||= 0
    end

    def self.call_count=(value)
      ActiveSupport::IsolatedExecutionState[:active_record_sql_call_count] = value
    end

    def self.query_cache_hits
      ActiveSupport::IsolatedExecutionState[:active_record_sql_query_cache_hits] ||= 0
    end

    def self.query_cache_hits=(value)
      ActiveSupport::IsolatedExecutionState[:active_record_sql_query_cache_hits] = value
    end

    alias_method :reset_runtime, :reset
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

require "active_support/notifications"

ActiveSupport::Notifications.subscribe("sql.active_record") do |event|
  ActiveRecord::RuntimeRegistry.call_count += 1
  ActiveRecord::RuntimeRegistry.query_cache_hits += 1 if event.payload[:cached]
end
