# a time consumer implementation for memchache
# install into application_controller.rb with the line
#
#   time_bandit TimeBandits::TimeConsumers::MemCache
#
require 'time_bandits/monkey_patches/memcache-client'
module TimeBandits
  module TimeConsumers
    class MemCache
      class << self
        def reset
          ::MemCache.reset_benchmarks
        end

        def consumed
          ::MemCache.get_benchmarks.first
        end

        def runtime
          ::MemCache.cache_runtime
        end
      end
    end
  end
end
