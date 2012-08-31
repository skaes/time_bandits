require "rails/rack/logger"

# A time_bandits compliant rack logger supporting rails tagged logging
#
# usage via an initializer (config/initializer/time_bandits.rb):
#
#   YourApp::Application.config.middleware.swap "TimeBandits::Rack::Logger", "TimeBandits::RailsRack::Logger",
#     YourApp::Application.config.log_tags
#
# hint for tagged logging with sysloglogger:
# you might need to wrap your sysloglogger in config/environments/production.rb within a tagged logger, like:
#
#   config.log_tags = [:uuid]
#   config.logger = ActiveSupport::TaggedLogging.new(SyslogLogger.new('zuperapp').tap do |l|
#     l.level = Logger::INFO
#   end)
#
module TimeBandits
  module RailsRack
    class Logger < ::Rails::Rack::Logger
      protected

      def before_dispatch(env)
        TimeBandits.reset
        Thread.current[:time_bandits_completed_info] = nil
      end

      # overwritten ::Rails::Rack::Logger#call_app
      def call_app(env)
        start_time = Time.now
        before_dispatch(env)

        request = ActionDispatch::Request.new(env)
        path = request.filtered_path
        Rails.logger.info "Started #{request.request_method} \"#{path}\" for #{request.ip} at #{start_time.to_default_s}"
        result = @app.call(env)
      ensure
        run_time = Time.now - start_time
        request_format = defined?(request) ? request.format : 'unknown'
        after_dispatch(env, result, run_time, request_format)

        # REM: this removes the tags, so we need to hack into Rails::Rack::Logger to get tags for
        # Completed line in after_dispatch
        ActiveSupport::LogSubscriber.flush_all!
      end

      def after_dispatch(env, result, run_time, request_format)
        status = result ? result.first : 500
        duration, additions, view_time, action = Thread.current[:time_bandits_completed_info]

        message = "Completed #{status} #{::Rack::Utils::HTTP_STATUS_CODES[status]} as '#{request_format}' in %.1fms" % (run_time*1000)
        message << " (#{additions.join(' | ')})" unless additions.blank?

        Rails.logger.info(message)
      end
    end
  end
end
