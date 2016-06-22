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
          i.calls += 1 #count redis round trips, not calls

          return unless logger.debug?

          name = "%s (%.2fms)" % ["Redis", event.duration]
          cmds = event.payload[:commands]

          # output = "  #{color(name, CYAN, true)}"
          output = "  #{name}"

          cmds.each do |cmd, *args|
            if args.present?
              logged_args = args.map do |a|
                case
                when a.respond_to?(:inspect) then a.inspect
                when a.respond_to?(:to_s)    then a.to_s
                else
                  # handle poorly-behaved descendants of BasicObject
                  klass = a.instance_exec { (class << self; self end).superclass }
                  "\#<#{klass}:#{a.__id__}>"
                end
              end

              output << " [ #{cmd.to_s.upcase} #{logged_args.join(" ")} ]"
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
