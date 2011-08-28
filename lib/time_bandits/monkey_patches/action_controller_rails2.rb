# =========================================================================================================
# IMPORTANT: the plugin changes the ActionController#process method chain
#
# the original rails stack looks like this:
#
# ActionController::SessionManagement#process_with_session_management_support
# ActionController::Filters#process_with_filters
# ActionController::Base#process
# ActionController::Caching::SqlCache#perform_action_with_caching
# ActionController::Rescue#perform_action_with_rescue
# *** ActionController::Benchmarking#perform_action_with_benchmark ***
# ActionController::Filters#perform_action_with_filters (==> this runs the filters)
# ActionController::Base#perform_action (==> run the action and eventually call render)
# ActionController::Benchmarking#render_with_benchmark (==> this is where the rendering time gets computed)
# ActionController::Base::render
#
# with the plugin installed, the stack looks like this:
#
# ActionController::SessionManagement#process_with_session_management_support
# ActionController::Filters#process_with_filters
# ActionController::Base#process
# *** ActionController::Benchmarking#perform_action_with_time_bandits ***   <=========== !!!!
# ActionController::Caching::SqlCache#perform_action_with_caching
# ActionController::Rescue#perform_action_with_rescue
# ActionController::Filters#perform_action_with_filters (==> this runs the filters)
# ActionController::Base#perform_action (==> run the action and eventually call render)
# ActionController::Benchmarking#render_with_benchmark (==> this is where the rendering time gets computed)
# ActionController::Base::render
# =========================================================================================================

module ActionController #:nodoc:

  class Base
    # this ugly hack is used to get the started_at and ip information into time bandits metrics
    def request_origin
      # this *needs* to be cached!
      # otherwise you'd get different results if calling it more than once
      @request_origin ||=
        begin
          remote_ip = request.remote_ip
          t = Time.now
          started_at = "#{t.to_s(:db)}.#{t.usec}"
          request.env["time_bandits.metrics"] = {:ip => remote_ip, :started_at => started_at}
          "#{remote_ip} at #{started_at}"
        end
    end
  end

  module TimeBanditry #:nodoc:
    def self.included(base)
      base.class_eval do
        alias_method_chain :perform_action, :time_bandits
        alias_method_chain :rescue_action, :time_bandits

        # if timebandits are used, the default benchmarking is
        # disabled. As alias_method_chain is unfriendly to extensions,
        # this is done by skipping perform_action_with_benchmarks by
        # calling perform_action_without_benchmarks at the appropriate
        # place.
        def perform_action_without_rescue
          perform_action_without_benchmark
        end

        alias_method :render, :render_with_benchmark
      end

      TimeBandits.add TimeBandits::TimeConsumers::Database.instance
    end

    def render_with_benchmark(options = nil, extra_options = {}, &block)
      if logger
        before_rendering = TimeBandits.consumed

        render_output = nil
        @view_runtime = Benchmark::realtime { render_output = render_without_benchmark(options, extra_options, &block) }

        other_time_consumed_during_rendering = TimeBandits.consumed - before_rendering
        @view_runtime -= other_time_consumed_during_rendering

        render_output
      else
        render_without_benchmark(options, extra_options, &block)
      end
    end

    def perform_action_with_time_bandits
      if logger
        TimeBandits.reset

        seconds = [ Benchmark::measure{ perform_action_without_time_bandits }.real, 0.0001 ].max

        log_message  = "Completed in #{sprintf("%.3f", seconds * 1000)}ms"

        log_message << " ("
        log_message << view_runtime
        TimeBandits.time_bandits.each do |bandit|
          log_message << ", #{bandit.runtime}"
        end
        log_message << ")"

        log_message << " | #{response.status}"
        log_message << " [#{complete_request_uri rescue "unknown"}]"

        logger.info(log_message)
        response.headers["X-Runtime"] = "#{sprintf("%.0f", seconds * 1000)}ms"
        merge_metrics(seconds)
      else
        perform_action_without_time_bandits
      end
    end

    def rescue_action_with_time_bandits(exception)
      # HACK!
      if logger && !caller.any?{|c| c =~ /perform_action_without_time_bandits/ }
        TimeBandits.reset

        seconds = [ Benchmark::measure{ rescue_action_without_time_bandits(exception) }.real, 0.0001 ].max

        log_message  = "Completed in #{sprintf("%.3f", seconds * 1000)}ms"

        log_message << " ("
        log_message << view_runtime
        TimeBandits.time_bandits.each do |bandit|
          log_message << ", #{bandit.runtime}"
        end
        log_message << ")"

        log_message << " | #{response.status}"
        log_message << " [#{complete_request_uri rescue "unknown"}]"

        logger.info(log_message)
        response.headers["X-Runtime"] = "#{sprintf("%.0f", seconds * 1000)}ms"
        merge_metrics(seconds)
      else
        rescue_action_without_time_bandits(exception)
      end
    end

    private

    def merge_metrics(total_time_seconds)
      basic_request_metrics = {
        :total_time => total_time_seconds * 1000,
        :view_time => (@view_runtime||0) * 1000,
        :code => response.status.to_i,
        :action => "#{self.class.name}\##{action_name}",
      }
      request.env["time_bandits.metrics"].merge!(TimeBandits.metrics).merge!(basic_request_metrics)
    end

    def view_runtime
      "View: %.3f" % ((@view_runtime||0) * 1000)
    end

  end
end
