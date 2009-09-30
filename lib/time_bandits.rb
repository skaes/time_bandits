# =========================================================================================================
# IMPORTANT: the plugin changes the ActionController#process method chain
#
# the original rails stack looks like this:
#
# ApplicationController#process_with_unload_user
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
# ApplicationController#process_with_unload_user
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

module TimeBandits
 # make active support autoloading happy
end

require 'time_bandits/monkey_patches/activerecord_adapter'

module ActionController #:nodoc:
  module TimeBanditry #:nodoc:
    def self.included(base)
      base.extend(ClassMethods)

      base.class_eval do
        alias_method_chain :perform_action, :time_bandits

        # if timebandits are used, the default benchmarking is
        # disabled. As alias_method_chain is unfriendly to extensions,
        # this is done by skipping perform_action_with_benchmarks by
        # calling perform_action_without_benchmarks at the appropriate
        # place.
        def perform_action_without_rescue
          perform_action_without_benchmark
        end

        alias_method :render, :render_with_benchmark

        # register database time consumer
        time_bandit TimeBandits::TimeConsumers::Database.new
      end
    end

    module ClassMethods
      def time_bandit(bandit)
        write_inheritable_attribute(:time_bandits,
            (read_inheritable_attribute(:time_bandits) || []) << bandit)
      end

      def time_bandits
        @time_bandits ||= read_inheritable_attribute(:time_bandits) || []
      end
    end

    def render_with_benchmark(options = nil, extra_options = {}, &block)
      if logger
        before_rendering = other_time_consumed_so_far

        render_output = nil
        @view_runtime = Benchmark::realtime { render_output = render_without_benchmark(options, extra_options, &block) }

        other_time_consumed_during_rendering = other_time_consumed_so_far - before_rendering
        @view_runtime -= other_time_consumed_during_rendering

        render_output
      else
        render_without_benchmark(options, extra_options, &block)
      end
    end

    def perform_action_with_time_bandits
      if logger
        reset_other_time_consumed_so_far

        seconds = [ Benchmark::measure{ perform_action_without_time_bandits }.real, 0.0001 ].max

        log_message  = "Completed in #{sprintf("%.3f", seconds * 1000)}ms"

        log_message << " ("
        log_message << view_runtime
        self.class.time_bandits.each do |bandit|
          log_message << ", #{bandit.runtime}"
        end
        log_message << ")"

        log_message << " | #{response.status}"
        log_message << " [#{complete_request_uri rescue "unknown"}]"

        logger.info(log_message)
        response.headers["X-Runtime"] = "#{sprintf("%.0f", seconds * 1000)}ms"
      else
        perform_action_without_time_bandits
      end
    end

    private
    def reset_other_time_consumed_so_far
      self.class.time_bandits.each{|bandit| bandit.reset}
    end

    def other_time_consumed_so_far
      self.class.time_bandits.map{|bandit| bandit.consumed}.sum
    end

    def view_runtime
      "View: %.3f" % ((@view_runtime||0) * 1000)
    end

  end
end
