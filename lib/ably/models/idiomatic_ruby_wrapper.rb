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
  # Wraps Hash objects returned by Ably service to appear as Idiomatic Ruby Hashes with symbol keys
  # It recursively wraps containing Hashes, but will stop wrapping at arrays, any other non Hash object, or any key matching the `:stops_at` options
  # It also provides methods matching the symbolic keys for convenience
  #
  # @example
  #   ruby_hash = IdiomaticRubyWrapper.new({ 'keyValue' => 'true' })
  #   # or recommended to avoid wrapping wrapped objects
  #   ruby_hash = IdiomaticRubyWrapper({ 'keyValue' => 'true' })
  #
  #   ruby_hash[:key_value] # => 'true'
  #   ruby_hash.key_value # => 'true'
  #   ruby_hash[:key_value] = 'new_value'
  #   ruby_hash.key_value # => 'new_value'
  #
  #   ruby_hash[:none] # => nil
  #   ruby_hash.none # => nil
  #
  # @!attribute [r] stop_at
  #   @return [Array<Symbol,String>] array of keys that this wrapper should stop wrapping at to preserve the underlying Hash as is
  #
  class IdiomaticRubyWrapper
    include Enumerable
    include Ably::Modules::Conversions
    include Ably::Modules::MessagePack

    attr_reader :stop_at

    # Creates an IdiomaticRubyWrapper around the mixed case Hash object
    #
    # @attribute [Hash] mixedCaseHashObject mixed case Hash object
    # @attribute [Array<Symbol,String>] stop_at array of keys that this wrapper should stop wrapping at to preserve the underlying Hash as is
    #
    def initialize(mixedCaseHashObject, options = {})
      stop_at = options.fetch(:stop_at, [])

      if mixedCaseHashObject.kind_of?(IdiomaticRubyWrapper)
        $stderr.puts "<IdiomaticRubyWrapper#initialize> WARNING: Wrapping a IdiomaticRubyWrapper with another IdiomaticRubyWrapper"
      end

      @attributes = mixedCaseHashObject
      @stop_at = Array(stop_at).each_with_object({}) do |key, object|
        object[convert_to_snake_case_symbol(key)] = true
      end.freeze
    end

    def [](key)
      value = attributes[source_key_for(key)]
      if stop_at?(key) || !value.kind_of?(Hash)
        value
      else
        IdiomaticRubyWrapper.new(value, stop_at: stop_at)
      end
    end

    def []=(key, value)
      attributes[source_key_for(key)] = value
    end

    def fetch(key, default = nil)
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
      attributes.size
    end

    def keys
      map { |key, value| key }
    end

    def values
      map { |key, value| value }
    end

    def has_key?(key)
      attributes.has_key?(source_key_for(key))
    end

    # Method ensuring this {IdiomaticRubyWrapper} is {http://ruby-doc.org/core-2.1.3/Enumerable.html Enumerable}
    def each
      return to_enum(:each) unless block_given?

      attributes.each do |key, value|
        key = convert_to_snake_case_symbol(key)
        value = self[key]
        yield key, value
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

    # @!attribute [r] Hash
    # @return [Hash] Access to the raw Hash object provided to the constructer of this wrapper
    def attributes
      @attributes
    end

    # Takes the underlying Hash object and returns it in as a JSON ready Hash object using camelCase for compability with the Ably service.
    # Note name clashes are ignored and will result in loss of one or more values
    # @example
    #   wrapper = IdiomaticRubyWrapper({ 'mixedCase': true, mixed_case: false, 'snake_case': 1 })
    #   wrapper.as_json => { 'mixedCase': true, 'snakeCase': 1 }
    def as_json(*args)
      attributes.each_with_object({}) do |key_val, new_hash|
        key                      = key_val[0]
        mixed_case_key           = convert_to_mixed_case(key)
        wrapped_val              = self[key]
        wrapped_val              = wrapped_val.as_json(args) if wrapped_val.kind_of?(IdiomaticRubyWrapper)

        new_hash[mixed_case_key] = wrapped_val
      end
    end

    # Converts the current wrapped mixedCase object to JSON
    # using snakedCase syntax as expected by the Realtime API
    def to_json(*args)
      as_json(args).to_json
    end

    # Generate a symbolized Hash object representing the underlying Hash in a Ruby friendly format.
    # Note name clashes are ignored and will result in loss of one or more values
    # @example
    #   wrapper = IdiomaticRubyWrapper({ 'mixedCase': true, mixed_case: false, 'snake_case': 1 })
    #   wrapper.to_hash => { mixed_case: true, snake_case: 1 }
    def to_hash(*args)
      each_with_object({}) do |key_val, object|
        key, val    = key_val
        val         = val.to_hash(args) if val.kind_of?(IdiomaticRubyWrapper)
        object[key] = val
      end
    end

    # Method to create a duplicate of the underlying Hash object
    # Useful when underlying Hash is frozen
    def dup
      Ably::Models::IdiomaticRubyWrapper.new(attributes.dup, stop_at: stop_at.keys)
    end

    # Freeze the underlying data
    def freeze
      attributes.freeze
    end

    def to_s
      attributes.to_s
    end

    # @!attribute [r] hash
    # @return [Integer] Compute a hash-code for this hash. Two hashes with the same content will have the same hash code
    def hash
      attributes.hash
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
        lambda { |key_sym| convert_to_mixed_case(key_sym) },
        lambda { |key_sym| key_sym.to_sym },
        lambda { |key_sym| key_sym.to_s },
        lambda { |key_sym| convert_to_mixed_case(key_sym).to_sym },
        lambda { |key_sym| convert_to_lower_case(key_sym) },
        lambda { |key_sym| convert_to_lower_case(key_sym).to_sym },
        lambda { |key_sym| convert_to_mixed_case(key_sym, force_camel: true) },
        lambda { |key_sym| convert_to_mixed_case(key_sym, force_camel: true).to_sym }
      ]

      preferred_format = format_preferences.detect do |format|
        attributes.has_key?(format.call(symbolized_key))
      end || format_preferences.first

      preferred_format.call(symbolized_key)
    end
  end
end
