module Ably::Models
  # Convert connection details attributes to a {ConnectionDetails} object
  #
  # @param attributes (see #initialize)
  #
  # @return [ConnectionDetails]
  #
  def self.ConnectionDetails(attributes)
    case attributes
    when ConnectionDetails
      return attributes
    else
      ConnectionDetails.new(attributes || {})
    end
  end

  # Contains any constraints a client should adhere to and provides additional metadata about a {Ably::Realtime::Connection},
  # such as if a request to {Ably::Realtime::Client#publish} a message that exceeds the maximum message size should be rejected immediately without communicating with Ably.
  #
  class ConnectionDetails
    include Ably::Modules::ModelCommon

    # Max message size
    MAX_MESSAGE_SIZE = 65536 # See spec TO3l8

    # Max frame size
    MAX_FRAME_SIZE = 524288 # See spec TO3l9

    # @param attributes [Hash]
    # @option attributes [String]    :client_id             Contains the client ID assigned to the token. If clientId is null or omitted, then the client is prohibited from assuming a clientId in any operations, however if clientId is a wildcard string *, then the client is permitted to assume any clientId. Any other string value for clientId implies that the clientId is both enforced and assumed for all operations from this client.
    # @option attributes [String]    :connection_key        the connection secret key string that is used to resume a connection and its state
    # @option attributes [Integer]   :max_message_size      maximum individual message size in bytes
    # @option attributes [Integer]   :max_frame_size        maximum size for a single frame of data sent to Ably. This restriction applies to a {Ably::Models::ProtocolMessage} sent over a realtime connection, or the total body size for a REST request
    # @option attributes [Integer]   :max_inbound_rate      maximum allowable number of requests per second from a client
    # @option attributes [Integer]   :max_idle_interval     is the maximum length of time in seconds that the server will allow no activity to occur in the server->client direction. After such a period of inactivity, the server will send a @HEARTBEAT@ or transport-level ping to the client. If the value is 0, the server will allow arbitrarily-long levels of inactivity.
    # @option attributes [Integer]   :connection_state_ttl  duration in seconds that Ably will persist the connection state when a Realtime client is abruptly disconnected
    # @option attributes [String]    :server_id             unique identifier of the Ably server where the connection is established
    #
    def initialize(attributes = {})
      @hash_object = IdiomaticRubyWrapper(attributes.clone)
      [:connection_state_ttl, :max_idle_interval].each do |duration_field|
        if self.attributes[duration_field]
          self.attributes[duration_field] = (self.attributes[duration_field].to_f / 1000).round
        end
      end
      self.attributes[:max_message_size] ||= MAX_MESSAGE_SIZE
      self.attributes[:max_frame_size] ||= MAX_FRAME_SIZE
      self.attributes.freeze
    end

    # Contains the client ID assigned to the token. If clientId is null or omitted, then the client is prohibited from
    # assuming a clientId in any operations, however if clientId is a wildcard string *, then the client is permitted
    # to assume any clientId. Any other string value for clientId implies that the clientId is both enforced and assumed
    # for all operations from this client.
    #
    # @spec RSA12a, CD2a
    #
    # @return [String]
    #
    def client_id
      attributes[:client_id]
    end

    # The connection secret key string that is used to resume a connection and its state.
    #
    # @spec RTN15e, CD2b
    #
    # @return [String]
    #
    def connection_key
      attributes[:connection_key]
    end

    # The duration that Ably will persist the connection state for when a Realtime client is abruptly disconnected.
    #
    # @spec CD2f, RTN14e, DF1a
    #
    # @return [Integer]
    #
    def connection_state_ttl
      attributes[:connection_state_ttl]
    end

    # Overrides the default maxFrameSize.
    #
    # @spec CD2d
    #
    # @return [Integer]
    #
    def max_frame_size
      attributes[:max_frame_size]
    end

    # The maximum allowable number of requests per second from a client or Ably. In the case of a realtime connection,
    # this restriction applies to the number of messages sent, whereas in the case of REST, it is the total number of REST requests per second.
    #
    # @spec CD2e
    #
    # @return [Integer]
    #
    def max_inbound_rate
      attributes[:max_inbound_rate]
    end

    # The maximum message size is an attribute of an Ably account and enforced by Ably servers.
    # maxMessageSize indicates the maximum message size allowed by the Ably account this connection is using.
    # Overrides the default value of ClientOptions.maxMessageSize.
    #
    # @spec CD2c
    #
    # @return [Integer]
    #
    def max_message_size
      attributes[:max_message_size]
    end

    # A unique identifier for the front-end server that the client has connected to. This server ID is only used for the purposes of debugging.
    #
    # @spec CD2g
    #
    # @return [String]
    #
    def server_id
      attributes[:server_id]
    end

    # The maximum length of time in milliseconds that the server will allow no activity to occur in the server to client direction.
    # After such a period of inactivity, the server will send a HEARTBEAT or transport-level ping to the client.
    # If the value is 0, the server will allow arbitrarily-long levels of inactivity.
    #
    # @spec CD2h
    #
    # @return [Integer]
    #
    def max_idle_interval
      attributes[:max_idle_interval]
    end

    def has_client_id?
      attributes.has_key?(:client_id)
    end

    # @return [Hash] Access the token details Hash object ruby'fied to use symbolized keys
    #
    def attributes
      @hash_object
    end
  end
end
