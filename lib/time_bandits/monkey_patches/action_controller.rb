module ActionController #:nodoc:

  require 'action_controller/metal/instrumentation'

  module Instrumentation

    # patch to ensure that the completed line is always written to the log.
    # this is not necessary anymore with rails 4.
    def process_action(action, *args)
      raw_payload = get_raw_payload
      ActiveSupport::Notifications.instrument("start_processing.action_controller", raw_payload.dup)

      exception = nil
      result = ActiveSupport::Notifications.instrument("process_action.action_controller", raw_payload) do |payload|
        begin
          super
        rescue Exception => exception
          response.status = 500
          nil
        ensure
          payload[:status] = response.status
          append_info_to_payload(payload)
        end
      end
      raise exception if exception
      result
    end unless Rails::VERSION::STRING =~ /\A4\./

    # patch to ensure that render times are always recorded in the log.
    def render(*args)
      render_output = nil
      exception = nil
      self.view_runtime = cleanup_view_runtime do
        Benchmark.ms do
          begin
            render_output = super
          rescue Exception => exception
          end
        end
      end
      raise exception if exception
      render_output
    end

    def cleanup_view_runtime #:nodoc:
      consumed_before_rendering = TimeBandits.consumed
      runtime = yield
      consumed_during_rendering = TimeBandits.consumed - consumed_before_rendering
      runtime - consumed_during_rendering
    end

    private

    if Rails::VERSION::STRING =~ /\A3\.[01]/
      def get_raw_payload
        {
          :controller => self.class.name,
          :action     => self.action_name,
          :params     => request.filtered_parameters,
          :formats    => request.formats.map(&:to_sym),
          :method     => request.method,
          :path       => (request.fullpath rescue "unknown")
        }
      end
    elsif Rails::VERSION::STRING =~ /\A3\.2/
      def get_raw_payload
        {
          :controller => self.class.name,
          :action     => self.action_name,
          :params     => request.filtered_parameters,
          :format     => request.format.try(:ref),
          :method     => request.method,
          :path       => (request.fullpath rescue "unknown")
        }
      end
    elsif Rails::VERSION::STRING !~ /\A4\.[012]/
      raise "time_bandits ActionController monkey patch is not compatible with your Rails version"
    end

    module ClassMethods
      # patch to log rendering time with more precision
      def log_process_action(payload) #:nodoc:
        messages, view_runtime = [], payload[:view_runtime]
        messages << ("Views: %.3fms" % view_runtime.to_f) if view_runtime
        messages
      end
    end
  end

  require 'action_controller/log_subscriber'

  class LogSubscriber
    # the original method logs the completed line.
    # but we do it in the middleware, unless we're in test mode. don't ask.
    def process_action(event)
      payload   = event.payload
      additions = ActionController::Base.log_process_action(payload)

      Thread.current.thread_variable_set(
        :time_bandits_completed_info,
        [ event.duration, additions, payload[:view_runtime], "#{payload[:controller]}##{payload[:action]}" ]
      )

      # this an ugly hack to encure completed lines show up in the test logs
      # TODO: move this code to some other place
      return unless Rails.env.test? && Rails::VERSION::STRING >= "3.2"

      status = payload[:status]
      if status.nil? && payload[:exception].present?
        exception_class_name = payload[:exception].first
        status = ActionDispatch::ExceptionWrapper.status_code_for_exception(exception_class_name)
      end
      message = "Completed #{status} #{Rack::Utils::HTTP_STATUS_CODES[status]} in %.1fms" % event.duration
      message << " (#{additions.join(" | ")})" unless additions.blank?

      info(message)
    end
  end

  # this gets included in ActionController::Base
  module TimeBanditry #:nodoc:
    extend ActiveSupport::Concern

    module ClassMethods
      def log_process_action(payload) #:nodoc:
        # need to call this to compute DB time/calls
        TimeBandits.consumed
        super.concat(TimeBandits.runtimes)
      end
    end

  end
end
