require "active_record/railties/controller_runtime"

module ActiveRecord
  module Railties
    module ControllerRuntime
      remove_method :cleanup_view_runtime
      def cleanup_view_runtime
        # this method has been redefined to do nothing for activerecord on purpose
        super
      end

      remove_method :append_info_to_payload
      def append_info_to_payload(payload)
        super
        if ActiveRecord::Base.connected?
          payload[:db_runtime] = TimeBandits::TimeConsumers::Database.instance.consumed
        end
      end

      module ClassMethods
        # this method has been redefined to do nothing for activerecord on purpose
        remove_method :log_process_action
        def log_process_action(payload)
          super
        end
      end
    end
  end
end
