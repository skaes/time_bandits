module TimeBandits
  module Rack
    class Logger < ActiveSupport::LogSubscriber
      def initialize(app, taggers=nil)
        @app = app
        @taggers = taggers || Rails.application.config.log_tags || []
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
        start_time = Time.now
        before_dispatch(request, env, start_time)
        result = @app.call(env)
      ensure
        run_time = Time.now - start_time
        after_dispatch(env, result, run_time)
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

      def before_dispatch(request, env, start_time)
        TimeBandits.reset
        Thread.current.thread_variable_set(:time_bandits_completed_info, nil)

        path = request.filtered_path

        debug ""
        info "Started #{request.request_method} \"#{path}\" for #{request.ip} at #{start_time.to_default_s}"
      end

      def after_dispatch(env, result, run_time)
        status = result ? result.first.to_i : 500
        completed_info = Thread.current.thread_variable_get(:time_bandits_completed_info)
        additions = completed_info[1] if completed_info

        message = "Completed #{status} #{::Rack::Utils::HTTP_STATUS_CODES[status]} in %.1fms" % run_time
        message << " (#{additions.join(' | ')})" unless additions.blank?
        info message
      ensure
        ActiveSupport::LogSubscriber.flush_all!
      end

    end
  end
end
