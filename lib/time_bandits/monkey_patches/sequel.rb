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
        start = Time.now
        _orig_log_connection_yield(*args, &block)
      ensure
        ActiveSupport::Notifications.instrument('duration.sequel', durationInSeconds: Time.now - start)
      end
    end

  else

    alias :_orig_log_yield :log_yield

    def log_yield(*args, &block)
      begin
        start = Time.now
        _orig_log_yield(*args, &block)
      ensure
        ActiveSupport::Notifications.instrument('duration.sequel', durationInSeconds: Time.now - start)
      end
    end

  end

end
