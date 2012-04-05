module TimeBandits
  module Rack
    class Logger < ActiveSupport::LogSubscriber
      # TODO: how to deal with tags
      def initialize(app, tags=nil)
        @app = app
      end

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
        TimeBandits.reset
        Thread.current[:time_bandits_completed_info] = nil

        request = ActionDispatch::Request.new(env)
        path = request.filtered_path

        info "\n\nStarted #{request.request_method} \"#{path}\" for #{request.ip} at #{start_time.to_default_s}"
      end

      def after_dispatch(env, result, run_time)
        status = result ? result.first : 500
        duration, additions, view_time, action = Thread.current[:time_bandits_completed_info]

        message = "Completed #{status} #{::Rack::Utils::HTTP_STATUS_CODES[status]} in %.1fms" % (run_time*1000)
        message << " (#{additions.join(' | ')})" unless additions.blank?
        info message
      ensure
        ActiveSupport::LogSubscriber.flush_all!
      end

    end
  end
end
