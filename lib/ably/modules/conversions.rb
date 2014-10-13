module Ably::Modules
  module Conversions
    extend self

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

    # Convert key to mixedCase from mixed_case
    def convert_to_mixed_case(key, force_camel: false)
      key.to_s.
        split('_').
        each_with_index.map do |str, index|
          if index > 0 || force_camel
            str.capitalize
          else
            str
          end
        end.
        join
    end

    # Convert key to :snake_case from snakeCase
    def convert_to_snake_case_symbol(key)
      key.to_s.gsub(/::/, '/').
        gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
        gsub(/([a-z\d])([A-Z])/,'\1_\2').
        gsub(/([a-zA-Z])(\d)/,'\1_\2').
        tr("-", "_").
        downcase.
        to_sym
    end

    def convert_to_lower_case(key)
      key.to_s.gsub('_', '')
    end
  end
end
