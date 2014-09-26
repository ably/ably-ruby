module Ably::Modules
  module Conversions
    private
    # Returns object as {IdiomaticRubyWrapper}
    def IdiomaticRubyWrapper(object, options = {})
      case object
      when Ably::Models::IdiomaticRubyWrapper
        object
      else
        Ably::Models::IdiomaticRubyWrapper.new(object, options)
      end
    end

    def as_since_epoch(time, granularity: :ms)
      case time
      when Time
        time.to_f * multiplier_from_granularity(granularity)
      when Numeric
        time
      else
        raise ArgumentError, "time argument must be a Numeric or Time object"
      end.to_i
    end

    def as_time_from_epoch(time, granularity: :ms)
      case time
      when Numeric
        Time.at(time / multiplier_from_granularity(granularity))
      when Time
        time
      else
        raise ArgumentError, "time argument must be a Numeric or Time object"
      end
    end

    def multiplier_from_granularity(granularity)
      case granularity
      when :ms # milliseconds
        1_000.0
      when :s # seconds
        1.0
      else
        raise ArgumentError, "invalid granularity"
      end
    end
  end
end
