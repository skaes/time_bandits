module TimeBandits
  class Railtie < Rails::Railtie

    initializer "time_bandits" do
      ActiveSupport.on_load(:action_controller) do
        require 'time_bandits/monkey_patches/rails_rack_logger'
        require 'time_bandits/monkey_patches/action_controller'
        include ActionController::TimeBanditry
      end

      ActiveSupport.on_load(:active_record) do
        require 'time_bandits/monkey_patches/activerecord_adapter'
        TimeBandits.add TimeBandits::TimeConsumers::Database.instance
      end
    end

  end
end
