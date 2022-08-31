require 'sequel'

major, minor, _ = Sequel.version.split('.').map(&:to_i)
if major < 4 || (major == 4 && minor < 15)
  raise "time_bandits Sequel monkey patch is not compatible with your sequel version"
end

Sequel::Database.class_eval do
  if instance_methods.include?(:log_connection_yield)

    alias :_orig_log_connection_yield :log_connection_yield

    def log_connection_yield(*args, &block)
      begin
        start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        _orig_log_connection_yield(*args, &block)
      ensure
        end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        ActiveSupport::Notifications.instrument('duration.sequel', durationInSeconds: end_time - start_time)
      end
    end

  else

    alias :_orig_log_yield :log_yield

    def log_yield(*args, &block)
      begin
        start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        _orig_log_yield(*args, &block)
      ensure
        end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        ActiveSupport::Notifications.instrument('duration.sequel', durationInSeconds: end_time - start_time)
      end
    end

  end

end
