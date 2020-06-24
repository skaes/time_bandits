# this file monkey patches class ActiveRecord::LogSubscriber
# to count the number of sql statements being executed
# and the number of query cache hits
# it needs to be adapted to each new rails version

require "active_record/log_subscriber"

module ActiveRecord
  class LogSubscriber
    IGNORE_PAYLOAD_NAMES = ["SCHEMA", "EXPLAIN"] unless defined?(IGNORE_PAYLOAD_NAMES)

    def self.call_count=(value)
      Thread.current.thread_variable_set(:active_record_sql_call_count, value)
    end

    def self.call_count
      Thread.current.thread_variable_get(:active_record_sql_call_count) ||
        Thread.current.thread_variable_set(:active_record_sql_call_count, 0)
    end

    def self.query_cache_hits=(value)
      Thread.current.thread_variable_set(:active_record_sql_query_cache_hits, value)
    end

    def self.query_cache_hits
      Thread.current.thread_variable_get(:active_record_sql_query_cache_hits) ||
        Thread.current.thread_variable_set(:active_record_sql_query_cache_hits, 0)
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

    remove_method :sql
    def sql(event)
      payload = event.payload

      self.class.runtime += event.duration
      self.class.call_count += 1
      self.class.query_cache_hits += 1 if payload[:cached] || payload[:name] == "CACHE"

      return unless logger.debug?

      return if IGNORE_PAYLOAD_NAMES.include?(payload[:name])

      log_sql_statement(payload, event)
    end

    private
    def log_sql_statement(payload, event)
      name  = "#{payload[:name]} (#{event.duration.round(1)}ms)"
      name  = "CACHE #{name}" if payload[:cached]
      sql   = payload[:sql]
      binds = nil

      unless (payload[:binds] || []).empty?
        casted_params = type_casted_binds(payload[:type_casted_binds])
        binds = "  " + payload[:binds].zip(casted_params).map { |attr, value|
          render_bind(attr, value)
        }.inspect
      end

      name = colorize_payload_name(name, payload[:name])
      sql  = color(sql, sql_color(sql), true)

      debug "  #{name}  #{sql}#{binds}"
    end
  end

  require "active_record/railties/controller_runtime"

  module Railties
    module ControllerRuntime
      remove_method :cleanup_view_runtime
      def cleanup_view_runtime
        # this method has been redefined to do nothing for activerecord on purpose
        super
      end

      remove_method :append_info_to_payload
      def append_info_to_payload(payload)
        super
        if ActiveRecord::Base.connected?
          payload[:db_runtime] = TimeBandits::TimeConsumers::Database.instance.consumed
        end
      end

      module ClassMethods
        # this method has been redefined to do nothing for activerecord on purpose
        remove_method :log_process_action
        def log_process_action(payload)
          super
        end
      end
    end
  end
end
