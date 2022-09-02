require 'redis'

if Redis::VERSION < "5.0"

  class Redis
    class Client
      alias :old_logging :logging

      def logging(commands, &block)
        ActiveSupport::Notifications.instrument('request.redis', commands: commands) do
          old_logging(commands, &block)
        end
      end
    end
  end

else

  module TimeBandits
    module RedisInstrumentation
      def call(command, redis_config)
        ActiveSupport::Notifications.instrument("request.redis", commands: [command]) do
          super
        end
      end

      def call_pipelined(commands, redis_config)
        ActiveSupport::Notifications.instrument("request.redis", commands: commands) do
          super
        end
      end
    end
  end
  RedisClient.register(TimeBandits::RedisInstrumentation)

end
