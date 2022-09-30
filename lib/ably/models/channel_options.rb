module Ably::Models
  # Convert token details argument to a {ChannelOptions} object
  #
  # @param attributes (see #initialize)
  #
  # @return [ChannelOptions]
  #
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

    # Describes the possible flags used to configure client capabilities, using {Ably::Models::ChannelOptions::MODES}.
    #
    #   PRESENCE		          The client can enter the presence set.
    #   PUBLISH		            The client can publish messages.
    #   SUBSCRIBE		          The client can subscribe to messages.
    #   PRESENCE_SUBSCRIBE		The client can receive presence messages.
    #
    # @spec TB2d
    #
    MODES = ruby_enum('MODES',
      presence: 0,
      publish: 1,
      subscribe: 2,
      presence_subscribe: 3
    )

    attr_reader :attributes

    alias_method :to_h, :attributes

    def_delegators :attributes, :fetch, :size, :empty?
    # Initialize a new ChannelOptions
    #
    # @spec TB3
    #
    # @option params [Hash] (TB2c) params (for realtime client libraries only) a  of key/value pairs
    # @option modes [Hash] modes (for realtime client libraries only) an array of ChannelMode
    # @option cipher [Hash,Ably::Models::CipherParams]   :cipher   A hash of options or a {Ably::Models::CipherParams} to configure the encryption. *:key* is required, all other options are optional.
    #
    def initialize(attrs)
      @attributes = IdiomaticRubyWrapper(attrs.clone)

      attributes[:modes] = modes.to_a.map { |mode| Ably::Models::ChannelOptions::MODES[mode] } if modes
      attributes[:cipher] = Ably::Models::CipherParams(cipher) if cipher
      attributes.clone
    end

    # Requests encryption for this channel when not null, and specifies encryption-related parameters (such as algorithm,
    # chaining mode, key length and key). See an example.
    #
    # @spec RSL5a, TB2b
    #
    # @return [CipherParams]
    #
    def cipher
      attributes[:cipher]
    end

    # Channel Parameters that configure the behavior of the channel.
    #
    # @spec TB2c
    #
    # @return [Hash]
    #
    def params
      attributes[:params].to_h
    end

    # An array of {Ably:Models:ChannelOptions::MODES} objects.
    #
    # @spec TB2d
    #
    # @return [Array<ChannelOptions::MODES>]
    #
    def modes
      attributes[:modes]
    end

    # Converts modes to a bitfield that coresponds to ProtocolMessage#flags
    #
    # @return [Integer]
    #
    def modes_to_flags
      modes.map { |mode| Ably::Models::ProtocolMessage::ATTACH_FLAGS_MAPPING[mode.to_sym] }.reduce(:|)
    end

    # @return [Hash]
    # @api private
    def set_params(hash)
      attributes[:params] = hash
    end

    # Sets modes from ProtocolMessage#flags
    #
    # @return [Array<ChannelOptions::MODES>]
    # @api private
    def set_modes_from_flags(flags)
      return unless flags

      message_modes = MODES.select do |mode|
        flag = Ably::Models::ProtocolMessage::ATTACH_FLAGS_MAPPING[mode.to_sym]
        flags & flag == flag
      end

      attributes[:modes] = message_modes.map { |mode| Ably::Models::ChannelOptions::MODES[mode] }
    end
  end
end
