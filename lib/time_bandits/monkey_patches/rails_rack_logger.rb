require 'rails/rack/logger'

module Rails
  module Rack
    class Logger

      def call(env)
        start_time = Time.now
        before_dispatch(env, start_time)
        result = @app.call(env)
      ensure
        run_time = Time.now - start_time
        after_dispatch(env, result, run_time)
      end

      protected
      def before_dispatch(env, start_time)
        Thread.current[:time_bandits_completed_info] = nil

        request = ActionDispatch::Request.new(env)
        path = request.fullpath

        info "\n\nStarted #{request.request_method} \"#{path}\" " \
             "for #{request.ip} at #{start_time.to_default_s}"
      end

      def after_dispatch(env, result, run_time)
        status = result ? result.first : 500
        duration, additions = Thread.current[:time_bandits_completed_info]

        message = "Completed #{status} #{::Rack::Utils::HTTP_STATUS_CODES[status]} in %.1fms" % (run_time*1000)
        message << " (#{additions.join(' | ')})" unless additions.blank?
        info message

        ActiveSupport::LogSubscriber.flush_all!
      end

    end
  end
end
