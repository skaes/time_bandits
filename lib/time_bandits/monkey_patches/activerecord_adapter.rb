# this file monkey patches class ActiveRecord::ConnectionAdapters::AbstractAdapter
# and the module module ActiveRecord::ConnectionAdapters::QueryCache
# to count the number of sql statements being executed.
# it needs to be adapted to each new rails version

raise "AR abstract adapter monkey patch for custom benchmarking is not compatible with your rails version" unless %w(2.3.2 2.3.3 2.3.4).include?(Rails::VERSION::STRING)

module ActiveRecord
  module ConnectionAdapters
    class AbstractAdapter
      attr_accessor :call_count, :query_cache_hits

      def initialize(connection, logger = nil) #:nodoc:
        @connection, @logger = connection, logger
        @runtime = 0
        @call_count = 0
        @last_verification = 0
        @query_cache_enabled = false
        @query_cache_hits = 0
      end

      def reset_call_count
        calls = @call_count
        @call_count = 0
        calls
      end

      def reset_query_cache_hits
        hits = @query_cache_hits
        @query_cache_hits = 0
        hits
      end

      protected
      def log(sql, name)
        if block_given?
          result = nil
          seconds = Benchmark.realtime { result = yield }
          @runtime += seconds
          @call_count += 1
          log_info(sql, name, seconds * 1000)
          result
        else
          log_info(sql, name, 0)
          nil
        end
      rescue Exception => e
        # Log message and raise exception.
        # Set last_verification to 0, so that connection gets verified
        # upon reentering the request loop
        @last_verification = 0
        message = "#{e.class.name}: #{e.message}: #{sql}"
        log_info(message, name, 0)
        raise ActiveRecord::StatementInvalid, message
      end
    end

    module QueryCache
      private
      def cache_sql(sql)
        result =
          if @query_cache.has_key?(sql)
            @query_cache_hits += 1
            log_info(sql, "CACHE", 0.0)
            @query_cache[sql]
          else
            @query_cache[sql] = yield
          end

        if Array === result
          result.collect { |row| row.dup }
        else
          result.duplicable? ? result.dup : result
        end
      rescue TypeError
        result
      end
    end
  end
end

