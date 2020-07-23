module TimeBandits

  module Rack
    autoload :Logger, 'time_bandits/rack/logger'
  end

  class Railtie < Rails::Railtie

    initializer "time_bandits" do |app|
      app.config.middleware.swap(Rails::Rack::Logger, TimeBandits::Rack::Logger)

      ActiveSupport.on_load(:action_controller) do
        require 'time_bandits/monkey_patches/action_controller'

        # Rails 5 may trigger the on_load event several times.
        next if included_modules.include?(ActionController::TimeBanditry)
        # For some magic reason, the test above is always false, but I'll leave it in
        # here, should the Rails team ever decide to change this behavior.

        include ActionController::TimeBanditry

        # make sure TimeBandits.reset is called in test environment as middlewares are not executed
        if Rails.env.test?
          require 'action_controller/test_case'
          # Rails 5 fires on_load events multiple times, so we need to protect against endless recursion here
          next if ActionController::TestCase::Behavior.instance_methods.include?(:process_without_time_bandits)
          module ActionController::TestCase::Behavior
            def process_with_time_bandits(*args, **kwargs)
              TimeBandits.reset
              process_without_time_bandits(*args, **kwargs)
            end
            alias_method :process_without_time_bandits, :process
            alias_method :process, :process_with_time_bandits
          end
        end
      end

      ActiveSupport.on_load(:active_record) do
        require 'time_bandits/monkey_patches/active_record'
        # TimeBandits.add is idempotent, so no need to protect against on_load fired multiple times.
        TimeBandits.add TimeBandits::TimeConsumers::Database
      end

      # Reset statistics info, so that for example the time for the first request handled
      # by the dispatcher is correct. Also: install GC time bandit here, as we want it to
      # be the last one in the log line.
      app.config.after_initialize do
        TimeBandits.add TimeBandits::TimeConsumers::GarbageCollection.instance if GC.respond_to? :enable_stats
        TimeBandits.reset
      end

    end

  end

end
