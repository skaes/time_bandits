# a time consumer implementation for memchached
# install into application_controller.rb with the line
#
#   time_bandit TimeBandits::TimeConsumers::Memcached
#
require 'time_bandits/monkey_patches/memcached'
module TimeBandits
  module TimeConsumers
    class Memcached
      class << self
        def reset
          ::Memcached.reset_benchmarks
        end

        def consumed
          ::Memcached.get_benchmarks.first
        end

        def runtime
          ::Memcached.cache_runtime
        end
      end
    end
  end
end
