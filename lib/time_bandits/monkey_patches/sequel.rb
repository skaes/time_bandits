require 'sequel'

major, minor, patch = Sequel.version.split('.').map(&:to_i)
raise "time_bandits Sequel monkey patch is not compatible with your sequel version" if
  major < 4 || (major == 4 && minor < 15)

Sequel::Database.class_eval do
  alias :_orig_log_yield :log_yield

  def log_yield(*args)
    begin
      start = Time.now
      _orig_log_yield(args) { yield if block_given? }
    ensure
      ActiveSupport::Notifications.instrument('duration.sequel', durationInSeconds: Time.now - start)
    end
  end
end
