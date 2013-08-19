# a time consumer implementation for redis
# install into application_controller.rb with the line
#
#   time_bandit TimeBandits::TimeConsumers::Redis
#
require 'time_bandits/monkey_patches/redis'

module TimeBandits
  module TimeConsumers
    class Redis < BaseConsumer
      prefix :redis
      fields :time, :calls
      format "Redis: %.3f(%d)", :time, :calls

      class Subscriber < ActiveSupport::LogSubscriber
        def request(event)
          i = Redis.instance
          i.time += event.duration
          i.calls += event.payload[:commands].size

          return unless logger.debug?

          name = "%s (%.2fms)" % ["Redis", event.duration]
          cmds = event.payload[:commands]

          # output = "  #{color(name, CYAN, true)}"
          output = "  #{name}"

          cmds.each do |cmd, *args|
            if args.present?
              output << " [ #{cmd.to_s.upcase} #{args.join(" ")} ]"
            else
              output << " [ #{cmd.to_s.upcase} ]"
            end
          end

          debug output
        end
      end
      Subscriber.attach_to(:redis)
    end
  end
end
