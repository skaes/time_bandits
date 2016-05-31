# a time consumer implementation for beetle publishing
# install into application_controller.rb with the line
#
#   time_bandit TimeBandits::TimeConsumers::Beetle
#

module TimeBandits
  module TimeConsumers
    class Beetle < BaseConsumer
      prefix :amqp
      fields :time, :calls
      format "Beetle: %.3f(%d)", :time, :calls

      class Subscriber < ActiveSupport::LogSubscriber
        def publish(event)

          i = Beetle.instance
          i.time += event.duration
          i.calls += 1

          return unless logger.debug?

          debug "%s (%.2fms)" % ["Beetle publish", event.duration]
        end
      end
      Subscriber.attach_to(:beetle)
    end
  end
end
