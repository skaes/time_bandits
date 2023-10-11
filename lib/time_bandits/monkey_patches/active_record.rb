if Gem::Version.new(ActiveRecord::VERSION::STRING) < Gem::Version.new("7.1.0")
  require_relative "active_record/log_subscriber"
else
  require_relative "active_record/runtime_registry"
end
require_relative "active_record/railties/controller_runtime"
