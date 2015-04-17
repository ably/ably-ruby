module Ably::Models
  class Stats
    # StatsStruct is a basic Struct like class that allows methods to be defined
    # on the class that will be retuned co-erced objects from the underlying hash used to
    # initialize the object.
    #
    # This class provides a concise way to create classes that have fixed attributes and types
    #
    # @example
    #   class MessageCount < StatsStruct
    #     coerce_attributes :count, :data, into: Integer
    #   end
    #
    # @api private
    #
    class StatsStruct
      class << self
        def coerce_attributes(*attributes)
          options = attributes.pop
          raise ArgumentError, 'Expected attribute into: within options hash' unless options.kind_of?(Hash) && options[:into]

          @type_klass = options[:into]
          setup_attribute_methods attributes
        end

        def type_klass
          @type_klass
        end

        private
        def setup_attribute_methods(attributes)
          attributes.each do |attr|
            define_method(attr) do
              # Lazy load the co-erced value only when accessed
              unless instance_variable_defined?("@#{attr}")
                instance_variable_set "@#{attr}", self.class.type_klass.new(hash[attr.to_sym])
              end
              instance_variable_get("@#{attr}")
            end
          end
        end
      end

      attr_reader :hash

      def initialize(hash)
        @hash = hash || {}
      end
    end

    # IntegerDefaultZero will always return an Integer object and will default to value 0 unless truthy
    #
    # @api private
    #
    class IntegerDefaultZero
      def self.new(value)
        (value && value.to_i) || 0
      end
    end

    # MessageCount contains aggregate counts for messages and data transferred
    # @!attribute [r] count
    #   @return [Integer] count of all messages
    # @!attribute [r] data
    #   @return [Integer] total data transferred for all messages in bytes
    class MessageCount < StatsStruct
      coerce_attributes :count, :data, into: IntegerDefaultZero
    end

    # RequestCount contains aggregate counts for requests made
    # @!attribute [r] succeeded
    #   @return [Integer] requests succeeded
    # @!attribute [r] failed
    #   @return [Integer] requests failed
    # @!attribute [r] refused
    #   @return [Integer] requests refused typically as a result of permissions or a limit being exceeded
    class RequestCount < StatsStruct
      coerce_attributes :succeeded, :failed, :refused, into: IntegerDefaultZero
    end

    # ResourceCount contains aggregate data for usage of a resource in a specific scope
    # @!attribute [r] opened
    #   @return [Integer] total resources of this type opened
    # @!attribute [r] peak
    #   @return [Integer] peak resources of this type used for this period
    # @!attribute [r] mean
    #   @return [Integer] average resources of this type used for this period
    # @!attribute [r] min
    #   @return [Integer] minimum total resources of this type used for this period
    # @!attribute [r] refused
    #   @return [Integer] resource requests refused within this period
    class ResourceCount < StatsStruct
      coerce_attributes :opened, :peak, :mean, :min, :refused, into: IntegerDefaultZero
    end

    # ConnectionTypes contains a breakdown of summary stats data for different (TLS vs non-TLS) connection types
    # @!attribute [r] tls
    #   @return [ResourceCount] TLS connection count
    # @!attribute [r] plain
    #   @return [ResourceCount] non-TLS connection count (unencrypted)
    # @!attribute [r] all
    #   @return [ResourceCount] all connection count (includes both TLS & non-TLS connections)
    class ConnectionTypes < StatsStruct
      coerce_attributes :tls, :plain, :all, into: ResourceCount
    end

    # MessageTypes contains a breakdown of summary stats data for different (message vs presence) message types
    # @!attribute [r] messages
    #   @return [MessageCount] count of channel messages
    # @!attribute [r] presence
    #   @return [MessageCount] count of presence messages
    # @!attribute [r] all
    #   @return [MessageCount] all messages count (includes both presence & messages)
    class MessageTypes < StatsStruct
      coerce_attributes :messages, :presence, :all, into: MessageCount
    end

    # MessageTraffic contains a breakdown of summary stats data for traffic over various transport types
    # @!attribute [r] realtime
    #   @return [MessageTypes] count of messages transferred over a realtime transport such as WebSockets
    # @!attribute [r] rest
    #   @return [MessageTypes] count of messages transferred using REST
    # @!attribute [r] webhook
    #   @return [MessageTypes] count of messages delivered using WebHooks
    # @!attribute [r] all
    #   @return [MessageTypes] all messages count (includes realtime, rest and webhook messages)
    class MessageTraffic < StatsStruct
      coerce_attributes :realtime, :rest, :webhook, :all, into: MessageTypes
    end
  end
end
