module ActionController #:nodoc:

  require 'action_controller/metal/instrumentation'

  module Instrumentation

    def cleanup_view_runtime #:nodoc:
      consumed_before_rendering = TimeBandits.consumed
      runtime = yield
      consumed_during_rendering = TimeBandits.consumed - consumed_before_rendering
      runtime - consumed_during_rendering
    end

    private

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

      # this is an ugly hack to ensure completed lines show up in the test logs
      # TODO: move this code to some other place
      return unless Rails.env.test?

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

  # this gets included in ActionController::Base in the time_bandits railtie
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
