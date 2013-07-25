module TimeBandits::TimeConsumers
  class BaseConsumer
    class << self
      def instance
        Thread.current.thread_variable_get(self.class.name) ||
          Thread.current.thread_variable_set(self.class.name, new)
      end

      # first symbol is used as time measurement
      def fields(*symbols)
        @struct = Struct.new(*symbols)
        symbols.each do |name|
          class_eval(<<-"EVA", __FILE__, __LINE__ + 1)
            def #{name}; @counters.#{name}; end
            def #{name}=(v); @counters.#{name} = v; end
          EVA
        end
      end

      def format(f, *keys)
        @runtime_format = f
        @runtime_keys = keys
      end

      attr_reader :struct, :timer_name, :runtime_format, :runtime_keys

      def method_missing(m, *args)
        (i = instance).respond_to?(m) ? i.send(m,*args) : super
      end
    end

    def initialize
      @counters = self.class.struct.new
      reset
    end

    def reset
      @counters.length.times{|i| @counters[i] = 0}
    end

    def metrics
      @counters.members.each_with_object({}){|m,h| h[m] = @counters.send(m)}
    end

    def consumed
      @counters[0]
    end

    def runtime
      self.class.runtime_format % metrics.values_at(*self.class.runtime_keys)
    end
  end
end
