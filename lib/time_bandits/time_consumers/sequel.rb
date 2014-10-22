# a time consumer implementation for sequel
# install into application_controller.rb with the line
#
#   time_bandit TimeBandits::TimeConsumers::Sequel
#
require 'time_bandits/monkey_patches/sequel'

module TimeBandits
  module TimeConsumers
    class Sequel < BaseConsumer
      prefix :db
      fields :time, :calls
      format "Sequel: %.3fms(%dq)", :time, :calls

      class Subscriber < ActiveSupport::LogSubscriber
        def duration(event)
          i = Sequel.instance
          i.time  += (event.payload[:durationInSeconds] * 1000)
          i.calls += 1
        end
      end
      Subscriber.attach_to(:sequel)
    end
  end
end