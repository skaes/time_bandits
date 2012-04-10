require 'action_controller/metal/instrumentation'
require 'action_controller/log_subscriber'

module ActionController #:nodoc:

  module Instrumentation

    # patch to ensure that the completed line is always written to the log
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
    end

    # patch to ensure that render times are always recorded in the log
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
      # TODO: time bandits all measure in seconds a.t.m.; this should be changed
      runtime - consumed_during_rendering*1000
    end

    private

    if Rails::VERSION::STRING =~ /^3\.[01]/
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
    elsif Rails::VERSION::STRING =~ /^3\.2/
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
    else
      raise "time_bandits ActionController monkey patch is not compatible with your Rails version"
    end

    module ClassMethods
      def log_process_action(payload) #:nodoc:
        messages, view_runtime = [], payload[:view_runtime]
        messages << ("Views: %.3fms" % view_runtime.to_f) if view_runtime
        messages
      end
    end
  end

  class LogSubscriber
    def process_action(event)
      payload   = event.payload
      additions = ActionController::Base.log_process_action(payload)
      Thread.current[:time_bandits_completed_info] =
        [ event.duration, additions, payload[:view_runtime], "#{payload[:controller]}##{payload[:action]}" ]
    end
  end

  module TimeBanditry #:nodoc:
    extend ActiveSupport::Concern

    module ClassMethods
      def log_process_action(payload) #:nodoc:
        messages = super
        TimeBandits.time_bandits.each do |bandit|
          messages << bandit.runtime
        end
        messages
      end
    end

  end
end
