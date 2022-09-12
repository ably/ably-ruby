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
    #
    # @spec TS5a, TS5b
    #
    class MessageCount < StatsStruct
      coerce_attributes :count, :data, into: IntegerDefaultZero
    end

    # RequestCount contains aggregate counts for requests made
    #
    # @spec TS8a, TS8b, TS8c
    #
    class RequestCount < StatsStruct
      coerce_attributes :succeeded, :failed, :refused, into: IntegerDefaultZero
    end

    # ResourceCount contains aggregate data for usage of a resource in a specific scope
    #
    class ResourceCount < StatsStruct
      coerce_attributes :opened, :peak, :mean, :min, :refused, into: IntegerDefaultZero
    end

    # ConnectionTypes contains a breakdown of summary stats data for different (TLS vs non-TLS) connection types
    #
    # @spec TS4a, TS4b, TS4c
    #
    class ConnectionTypes < StatsStruct
      coerce_attributes :tls, :plain, :all, into: ResourceCount
    end

    # MessageTypes contains a breakdown of summary stats data for different (message vs presence) message types
    #
    # @spec TS6a, TS6b, TS6c
    #
    class MessageTypes < StatsStruct
      coerce_attributes :messages, :presence, :all, into: MessageCount
    end

    # MessageTraffic contains a breakdown of summary stats data for traffic over various transport types
    #
    # @spec TS7a, TS7b, TS7c, TS7d
    #
    class MessageTraffic < StatsStruct
      coerce_attributes :realtime, :rest, :webhook, :all, into: MessageTypes
    end
  end
end
