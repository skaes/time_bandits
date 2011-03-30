require 'rails/rack/logger'

module Rails
  module Rack
    class Logger

      def call(env)
        start_time = before_dispatch(env)
        result = @app.call(env)
      ensure
        run_time = Time.now - start_time
        after_dispatch(env, result, run_time)
      end

      protected
      def before_dispatch(env)
        Thread.current[:time_bandits_completed_info] = nil

        start_time = Time.now
        request = ActionDispatch::Request.new(env)
        path = request.fullpath

        info "\n\nStarted #{request.request_method} \"#{path}\" " \
             "for #{request.ip} at #{start_time.to_default_s}"
        start_time
      end

      def after_dispatch(env, result, run_time)
        status = result.first
        duration, additions = Thread.current[:time_bandits_completed_info]

        message = "Completed #{status} #{::Rack::Utils::HTTP_STATUS_CODES[status]} in %.1fms"
        message << " (#{additions.join(' | ')})" % (run_time*1000) unless additions.blank?
        info message

        ActiveSupport::LogSubscriber.flush_all!
      end

    end
  end
end
