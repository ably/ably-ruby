module Ably::Models
  # Convert token details argument to a {ChannelOptions} object
  #
  # @param attributes (see #initialize)
  #
  # @return [ChannelOptions]
  def self.ChannelOptions(attributes)
    case attributes
    when ChannelOptions
      return attributes
    else
      ChannelOptions.new(attributes)
    end
  end

  # Represents options of a channel
  class ChannelOptions
    extend Ably::Modules::Enum
    extend Forwardable
    include Ably::Modules::ModelCommon

    MODES = ruby_enum('MODES',
      presence: 0,
      publish: 1,
      subscribe: 2,
      presence_subscribe: 3
    )

    attr_reader :attributes

    alias_method :to_h, :attributes

    def_delegators :attributes, :fetch
    # Initialize a new ChannelOptions
    #
    # @option params [Hash] (TB2c) params (for realtime client libraries only) a  of key/value pairs
    # @option modes [Hash] modes (for realtime client libraries only) an array of ChannelMode
    # @option cipher [Hash,Ably::Models::CipherParams]   :cipher   A hash of options or a {Ably::Models::CipherParams} to configure the encryption. *:key* is required, all other options are optional.
    #
    def initialize(attributes)
      @attributes = IdiomaticRubyWrapper(attributes.clone)

      attributes[:cipher] = Ably::Models::CipherParams(cipher) if cipher
      attributes.clone
    end

    # @!attribute cipher
    #
    # @return [CipherParams]
    def cipher
      attributes[:cipher]
    end

    # @!attribute params
    #
    # @return [Hash]
    def params
      attributes[:params].to_h
    end

    # @!attribute modes
    #
    # @return [Array<>]
    def modes
      attributes[:modes].to_a
    end
  end
end
