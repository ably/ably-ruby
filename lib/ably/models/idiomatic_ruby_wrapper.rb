require 'logger'

module Ably::Modules
  module Conversions
    private
    # Creates or returns an {IdiomaticRubyWrapper} ensuring it never wraps itself
    #
    # @return {IdiomaticRubyWrapper}
    def IdiomaticRubyWrapper(object, options = {})
      case object
      when Ably::Models::IdiomaticRubyWrapper
        object
      else
        Ably::Models::IdiomaticRubyWrapper.new(object, options)
      end
    end
  end
end

module Ably::Models
  # Wraps JSON objects returned by Ably service to appear as Idiomatic Ruby Hashes with symbol keys
  # It recursively wraps containing Hashes, but will stop wrapping at arrays, any other non Hash object, or any key matching the `:stops_at` options
  # It also provides methods matching the symbolic keys for convenience
  #
  # @example
  # ruby_hash = IdiomaticRubyWrapper.new({ 'keyValue' => 'true' })
  # # or recommended to avoid wrapping wrapped objects
  # ruby_hash = IdiomaticRubyWrapper({ 'keyValue' => 'true' })

  # ruby_hash[:key_value] # => 'true'
  # ruby_hash.key_value # => 'true'
  # ruby_hash[:key_value] = 'new_value'
  # ruby_hash.key_value # => 'new_value'
  #
  # ruby_hash[:none] # => nil
  # ruby_hash.none # => nil
  #
  # @!attribute [r] stop_at
  #   @return [Array<Symbol,String>] array of keys that this wrapper should stop wrapping at to preserve the underlying JSON hash as is
  #
  class IdiomaticRubyWrapper
    include Enumerable
    include Ably::Modules::Conversions

    attr_reader :stop_at

    # Creates an IdiomaticRubyWrapper around the mixed case JSON object
    #
    # @attribute [Hash] mixedCaseJsonObject mixed case JSON object
    # @attribute [Array<Symbol,String>] stop_at array of keys that this wrapper should stop wrapping at to preserve the underlying JSON hash as is
    #
    def initialize(mixedCaseJsonObject, stop_at: [])
      if mixedCaseJsonObject.kind_of?(IdiomaticRubyWrapper)
        $stderr.puts "<IdiomaticRubyWrapper#initialize> WARNING: Wrapping a IdiomaticRubyWrapper with another IdiomaticRubyWrapper"
      end

      @json = mixedCaseJsonObject
      @stop_at = Array(stop_at).each_with_object({}) do |key, hash|
        hash[convert_to_snake_case_symbol(key)] = true
      end.freeze
    end

    def [](key)
      value = json[source_key_for(key)]
      if stop_at?(key) || !value.kind_of?(Hash)
        value
      else
        IdiomaticRubyWrapper.new(value, stop_at: stop_at)
      end
    end

    def []=(key, value)
      json[source_key_for(key)] = value
    end

    def fetch(key, default = nil, &missing_block)
      if has_key?(key)
        self[key]
      else
        if default
          default
        elsif block_given?
          yield key
        else
          raise KeyError, "key not found: #{key}"
        end
      end
    end

    def size
      json.size
    end

    def keys
      map { |key, value| key }
    end

    def values
      map { |key, value| value }
    end

    def has_key?(key)
      json.has_key?(source_key_for(key))
    end

    # Method ensuring this {IdiomaticRubyWrapper} is {http://ruby-doc.org/core-2.1.3/Enumerable.html Enumerable}
    def each(&block)
      json.each do |key, value|
        key = convert_to_snake_case_symbol(key)
        value = self[key]
        if block_given?
          block.call key, value
        else
          yield key, value
        end
      end
    end

    # Compare object based on Hash equivalent
    def ==(other)
      return false unless other.kind_of?(self.class) || other.kind_of?(Hash)

      other = other.to_hash if other.kind_of?(self.class)
      to_hash == other
    end

    def method_missing(method_sym, *arguments)
      key = method_sym.to_s.gsub(%r{=$}, '')
      return super if !has_key?(key)

      if method_sym.to_s.match(%r{=$})
        raise ArgumentError, "Cannot set #{method_sym} with more than one argument" unless arguments.length == 1
        self[key] = arguments.first
      else
        raise ArgumentError, "Cannot pass an argument to #{method_sym} when retrieving its value" unless arguments.empty?
        self[method_sym]
      end
    end

    # Access to the raw JSON object provided to the constructer of this wrapper
    def json
      @json
    end

    # Converts the current wrapped mixedCase object to a JSON string
    # using the provided mixedCase syntax
    def to_json(*args)
      json.to_json
    end

    # Generate a symbolized Hash object representing the underlying JSON in a Ruby friendly format
    def to_hash
      each_with_object({}) do |key_val, hash|
        key, val = key_val
        hash[key] = val
      end
    end

    # Method to create a duplicate of the underlying JSON object
    # Useful when underlying JSON is frozen
    def dup
      Ably::Models::IdiomaticRubyWrapper.new(json.dup)
    end

    private
    def stop_at?(key)
      @stop_at.has_key?(key)
    end

    # We assume by default all keys are interchangeable between :this_format and 'thisFormat'
    # However, this method will find other fallback formats such as CamelCase or :symbols if a matching
    # key is not found in mixedCase.
    def source_key_for(symbolized_key)
      format_preferences = [
        -> (key_sym) { convert_to_mixed_case(key_sym) },
        -> (key_sym) { key_sym.to_sym },
        -> (key_sym) { key_sym.to_s },
        -> (key_sym) { convert_to_mixed_case(key_sym).to_sym },
        -> (key_sym) { convert_to_lower_case(key_sym) },
        -> (key_sym) { convert_to_lower_case(key_sym).to_sym },
        -> (key_sym) { convert_to_mixed_case(key_sym, force_camel: true) },
        -> (key_sym) { convert_to_mixed_case(key_sym, force_camel: true).to_sym }
      ]

      preferred_format = format_preferences.detect do |format|
        json.has_key?(format.call(symbolized_key))
      end || format_preferences.first

      preferred_format.call(symbolized_key)
    end
  end
end
