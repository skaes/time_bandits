module TimeBandits

  module Rack
    if Rails::VERSION::STRING >= "4.0"
      autoload :Logger, 'time_bandits/rack/logger40'
    else
      autoload :Logger, 'time_bandits/rack/logger'
    end
  end

  class Railtie < Rails::Railtie

    initializer "time_bandits" do |app|
      app.config.middleware.swap(Rails::Rack::Logger, TimeBandits::Rack::Logger)

      ActiveSupport.on_load(:action_controller) do
        require 'time_bandits/monkey_patches/action_controller'
        include ActionController::TimeBanditry

        # make sure TimeBandits.reset is called in test environment as middlewares are not executed
        if Rails.env.test?
          module TestWithTimeBanditsReset
            def process(*args)
              TimeBandits.reset
              super
            end
          end
          require 'action_controller/test_case'
          ActionController::TestCase::Behavior.prepend TestWithTimeBanditsReset
        end
      end

      ActiveSupport.on_load(:active_record) do
        require 'time_bandits/monkey_patches/active_record'
        TimeBandits.add TimeBandits::TimeConsumers::Database
      end

      # reset statistics info, so that for example the time for the first request handled
      # by the dispatcher is correct.
      app.config.after_initialize do
        TimeBandits.reset
      end

    end

  end

end
