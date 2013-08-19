module TimeBandits::TimeConsumers
  class BaseConsumer
    class << self
      def instance
        Thread.current.thread_variable_get(name) ||
          Thread.current.thread_variable_set(name, new)
      end

      def prefix(sym)
        @metrics_prefix = sym
      end

      # first symbol is used as time measurement
      def fields(*symbols)
        @struct = Struct.new(*(symbols.map{|s| "#{@metrics_prefix}_#{s}".to_sym}))
        symbols.each do |name|
          class_eval(<<-"EVA", __FILE__, __LINE__ + 1)
            def #{name}; @counters.#{@metrics_prefix}_#{name}; end
            def #{name}=(v); @counters.#{@metrics_prefix}_#{name} = v; end
          EVA
        end
      end

      def format(f, *keys)
        @runtime_format = f
        @runtime_keys = keys.map{|s| "#{@metrics_prefix}_#{s}".to_sym}
      end

      attr_reader :metrics_prefix, :struct, :timer_name, :runtime_format, :runtime_keys

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
      values = metrics.values_at(*self.class.runtime_keys)
      if values.all?{|v|v==0}
        ""
      else
        self.class.runtime_format % values
      end
    end
  end
end
