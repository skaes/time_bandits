require 'rails/rack/logger'

module Rails
  module Rack
    class Logger

      def call(env)
        start_time = before_dispatch(env)
        @app.call(env)
      ensure
        run_time = Time.now - start_time
        info "Request processing completed in #{sprintf("%.1f", run_time*1000)}ms"
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
