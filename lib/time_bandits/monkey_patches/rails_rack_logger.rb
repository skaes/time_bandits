require 'rails/rack/logger'

module Rails
  module Rack
    class Logger

      def call(env)
        start_time = before_dispatch(env)
        result = @app.call(env)
      ensure
        run_time = Time.now - start_time
        status = result.first
        duration, additions = Thread.current[:time_bandits_completed_info]
        puts additions.inspect
        (additions ||= []).insert(0, "Controller: %.1f" % duration)

        message = "Completed #{status} #{::Rack::Utils::HTTP_STATUS_CODES[status]} in %.1fms (#{additions.join(' | ')})" % (run_time*1000)
        info message

        after_dispatch(env)
      end

      protected
      def before_dispatch(env)
        start_time = Time.now
        request = ActionDispatch::Request.new(env)
        path = request.fullpath

        info "\n\nStarted #{request.request_method} \"#{path}\" " \
             "for #{request.ip} at #{start_time.to_default_s}"
        start_time
      end

    end
  end
end
