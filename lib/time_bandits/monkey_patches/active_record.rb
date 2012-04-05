# this file monkey patches class ActiveRecord::LogSubscriber
# to count the number of sql statements being executed
# and the number of query cache hits
# it needs to be adapted to each new rails version

raise "time_bandits ActiveRecord monkey patch is not compatible with your rails version" unless
  Rails::VERSION::STRING =~ /^3\.[012]/

require "active_record/log_subscriber"

module ActiveRecord
  class LogSubscriber

    def self.call_count=(value)
      Thread.current["active_record_sql_call_count"] = value
    end

    def self.call_count
      Thread.current["active_record_sql_call_count"] ||= 0
    end

    def self.query_cache_hits=(value)
      Thread.current["active_record_sql_query_cache_hits"] = value
    end

    def self.query_cache_hits
      Thread.current["active_record_sql_query_cache_hits"] ||= 0
    end

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

    def sql(event)
      self.class.runtime += event.duration
      self.class.call_count += 1
      self.class.query_cache_hits += 1 if event.payload[:name] == "CACHE"

      return unless logger.debug?

      payload = event.payload

      return if 'SCHEMA' == payload[:name]

      name = '%s (%.1fms)' % [payload[:name], event.duration]
      sql  = payload[:sql].squeeze(' ')
      binds = nil

      unless (payload[:binds] || []).empty?
        binds = "  " + payload[:binds].map { |col,v|
          [col.name, v]
        }.inspect
      end

      if odd?
        name = color(name, CYAN, true)
        sql  = color(sql, nil, true)
      else
        name = color(name, MAGENTA, true)
      end

      debug "  #{name}  #{sql}#{binds}"
    end
  end

  module Railties
    module ControllerRuntime
      def cleanup_view_runtime
        super
      end
      module ClassMethods
        def log_process_action(payload)
          super
        end
      end
    end
  end
end

