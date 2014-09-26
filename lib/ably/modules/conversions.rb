module Ably::Modules
  module Conversions
    private
    # Take a Hash object and make it more Ruby like converting all keys
    # into symbols with snake_case notation
    def rubify(*args)
      convert_hash_recursively(*args) do |key|
        convert_to_snake_case(key).to_sym
      end
    end

    # Take a Hash object and make it more Java like converting all keys
    # into strings with mixedCase notation
    def javify(*args)
      convert_hash_recursively(*args) do |key|
        convert_to_mixed_case(key).to_s
      end
    end

    def convert_hash_recursively(hash, ignore: [], &processing_block)
      raise ArgumentError, "Processing block is missing" unless block_given?

      return hash unless hash.kind_of?(Hash)

      Hash[hash.map do |key, val|
        key_sym       = yield(key)
        converted_val = if ignore.include?(key_sym)
          val
        else
          convert_hash_recursively(val, ignore: ignore, &processing_block)
        end

        [key_sym, converted_val]
      end]
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

    def convert_to_mixed_case(string_like)
      string_like.to_s.
        split('_').
        each_with_index.map do |str, index|
          if index > 0
            str.capitalize
          else
            str
          end
        end.
        join
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

    def convert_to_snake_case(string_like)
      string_like.to_s.gsub(/::/, '/').
        gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
        gsub(/([a-z\d])([A-Z])/,'\1_\2').
        tr("-", "_").
        downcase
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
