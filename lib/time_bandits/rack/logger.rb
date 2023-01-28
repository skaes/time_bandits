require 'active_support/core_ext/time/conversions'
require 'active_support/core_ext/object/blank'
require 'active_support/log_subscriber'
require 'action_dispatch/http/request'
require 'rack/body_proxy'

module TimeBandits
  module Rack
    # Sets log tags, logs the request, calls the app, and flushes the logs.
    class Logger < ActiveSupport::LogSubscriber
      def initialize(app, taggers = nil)
        @app          = app
        @taggers      = taggers || Rails.application.config.log_tags || []
        @instrumenter = ActiveSupport::Notifications.instrumenter
      end

      def call(env)
        request = ActionDispatch::Request.new(env)

        if logger.respond_to?(:tagged) && !@taggers.empty?
          logger.tagged(compute_tags(request)) { call_app(request, env) }
        else
          call_app(request, env)
        end
      end

    protected

      def call_app(request, env)
        start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        start(request, Time.now)
        resp = @app.call(env)
        resp[2] = ::Rack::BodyProxy.new(resp[2]) { finish(request) }
        resp
      rescue
        finish(request)
        raise
      ensure
        end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        completed(request, (end_time - start_time) * 1000, resp)
        ActiveSupport::LogSubscriber.flush_all!
      end

      # Started GET "/session/new" for 127.0.0.1 at 2012-09-26 14:51:42 -0700
      def started_request_message(request, start_time = Time.now)
        'Started %s "%s" for %s at %s' % [
          request.request_method,
          request.filtered_path,
          request.ip,
          start_time.to_default_s ]
      end

      def compute_tags(request)
        @taggers.collect do |tag|
          case tag
          when Proc
            tag.call(request)
          when Symbol
            request.send(tag)
          else
            tag
          end
        end
      end

      private

      def start(request, start_time)
        TimeBandits.reset
        Thread.current.thread_variable_set(:time_bandits_completed_info, nil)
        @instrumenter.start 'action_dispatch.request', request: request

        logger.debug ""
        logger.info started_request_message(request, start_time)
      end

      def completed(request, run_time, resp)
        status = resp ? resp.first.to_i : 500
        completed_info = Thread.current.thread_variable_get(:time_bandits_completed_info)
        additions = completed_info[1] if completed_info
        message = "Completed #{status} #{::Rack::Utils::HTTP_STATUS_CODES[status]} in %.1fms" % run_time
        message << " (#{additions.join(' | ')})" unless additions.blank?
        logger.info message
      end

      def finish(request)
        @instrumenter.finish 'action_dispatch.request', request: request
      end

      def logger
        @logger ||= Rails.logger
      end
    end
  end
end
