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
    end

    def convert_to_snake_case(string_like)
      string_like.to_s.gsub(/::/, '/').
        gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
        gsub(/([a-z\d])([A-Z])/,'\1_\2').
        tr("-", "_").
        downcase
    end
  end
end
