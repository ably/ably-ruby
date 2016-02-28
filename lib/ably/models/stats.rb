require 'ably/models/stats_types'

module Ably::Models
  # Convert stat argument to a {Stats} object
  #
  # @param stat [Stats,Hash] A Stats object or Hash of stat properties
  #
  # @return [Stats]
  def self.Stats(stat)
    case stat
    when Stats
      stat
    else
      Stats.new(stat)
    end
  end

  # A class representing an individual statistic for a specified {#interval_id}
  #
  # @!attribute [r] all
  #   @return [Stats::MessageTypes] Breakdown of summary stats for all message types
  # @!attribute [r] inbound
  #   @return [Stats::MessageTraffic] Breakdown of summary stats for traffic over various transport types for all inbound messages
  # @!attribute [r] outbound
  #   @return [Stats::MessageTraffic] Breakdown of summary stats for traffic over various transport types for all outbound messages
  # @!attribute [r] persisted
  #   @return [Stats::MessageTypes] Breakdown of summary stats for all persisted messages
  # @!attribute [r] connections
  #   @return [Stats::ConnectionTypes] A breakdown of summary stats data for different (TLS vs non-TLS) connection types.
  # @!attribute [r] channels
  #   @return [Stats::ResourceCount] Aggregate data for usage of Channels
  # @!attribute [r] api_requests
  #   @return [Stats::RequestCount] Aggregate data for numbers of API requests
  # @!attribute [r] token_requests
  #   @return [Stats::RequestCount] Aggregate data for numbers of Token requests
  #
  class Stats
    include Ably::Modules::ModelCommon
    extend Ably::Modules::Enum

    GRANULARITY = ruby_enum('GRANULARITY',
      :minute,
      :hour,
      :day,
      :month
    )

    INTERVAL_FORMAT_STRING = [
      '%Y-%m-%d:%H:%M',
      '%Y-%m-%d:%H',
      '%Y-%m-%d',
      '%Y-%m'
    ]

    class << self
      # Convert a Time with the specified Granularity into an interval ID based on UTC 0 time
      # @example
      #   Stats.to_interval_id(Time.now, :hour) # => '2015-01-01:10'
      #
      # @param time [Time] Time used to determine the interval
      # @param granularity [GRANULARITY] Granularity of the metrics such as :hour, :day
      #
      # @return [String] interval ID used for stats
      #
      def to_interval_id(time, granularity)
        raise ArgumentError, 'Time object required as first argument' unless time.kind_of?(Time)

        granularity = GRANULARITY(granularity)
        format = INTERVAL_FORMAT_STRING[granularity.to_i]

        time.utc.strftime(format)
      end

      # Returns the UTC 0 start Time of an interval_id
      # @example
      #   Stats.from_interval_id('2015-01-01:10') # => 2015-01-01 10:00:00 +0000
      #
      # @param interval_id [String]
      #
      # @return [Time] start time of the provided interval_id
      #
      def from_interval_id(interval_id)
        raise ArgumentError, 'Interval ID must be a string' unless interval_id.kind_of?(String)

        format = INTERVAL_FORMAT_STRING.find { |fmt| expected_length(fmt) == interval_id.length }
        raise ArgumentError, 'Interval ID is an invalid length' unless format

        Time.strptime("#{interval_id} +0000", "#{format} %z").utc
      end

      # Returns the {GRANULARITY} determined from the interval_id
      # @example
      #   Stats.granularity_from_interval_id('2015-01-01:10') # => :hour
      #
      # @param interval_id [String]
      #
      # @return [GRANULARITY] Granularity Enum for the interval_id
      #
      def granularity_from_interval_id(interval_id)
        raise ArgumentError, 'Interval ID must be a string' unless interval_id.kind_of?(String)

        format = INTERVAL_FORMAT_STRING.find { |fmt| expected_length(fmt) == interval_id.length }
        raise ArgumentError, 'Interval ID is an invalid length' unless format

        GRANULARITY[INTERVAL_FORMAT_STRING.index(format)]
      end

      private
      def expected_length(format)
        format.gsub('%Y', 'YYYY').length
      end
    end

    # {Stats} initializer
    #
    # @param hash_object  [Hash]  object with the underlying stat details
    #
    def initialize(hash_object)
      @raw_hash_object  = hash_object
      set_attributes_object hash_object
    end

    # Aggregates inbound and outbound messages
    # @return {Stats::MessageTypes}
    def all
      @all ||= Stats::MessageTypes.new(attributes[:all])
    end

    # All inbound messages i.e. received by Ably from clients
    # @return {Stats::MessageTraffic}
    def inbound
      @inbound ||= Stats::MessageTraffic.new(attributes[:inbound])
    end

    # All outbound messages i.e. sent from Ably to clients
    # @return {Stats::MessageTraffic}
    def outbound
      @outbound ||= Stats::MessageTraffic.new(attributes[:outbound])
    end

    # Messages persisted for later retrieval via the history API
    # @return {Stats::MessageTypes}
    def persisted
      @persisted ||= Stats::MessageTypes.new(attributes[:persisted])
    end

    # Breakdown of connection stats data for different (TLS vs non-TLS) connection types
    # @return {Stats::ConnectionTypes}
    def connections
      @connections ||= Stats::ConnectionTypes.new(attributes[:connections])
    end

    # Breakdown of channels stats
    # @return {Stats::ResourceCount}
    def channels
      @channels ||= Stats::ResourceCount.new(attributes[:channels])
    end

    # Breakdown of API requests received via the REST API
    # @return {Stats::RequestCount}
    def api_requests
      @api_requests ||= Stats::RequestCount.new(attributes[:api_requests])
    end

    # Breakdown of Token requests received via the REST API
    # @return {Stats::RequestCount}
    def token_requests
      @token_requests ||= Stats::RequestCount.new(attributes[:token_requests])
    end

    # @!attribute [r] interval_id
    # @return [String] The interval that this statistic applies to, see {GRANULARITY} and {INTERVAL_FORMAT_STRING}
    def interval_id
      attributes.fetch(:interval_id)
    end

    # @!attribute [r] interval_time
    # @return [Time] A Time object representing the start of the interval
    def interval_time
      self.class.from_interval_id(interval_id)
    end

    # @!attribute [r] interval_granularity
    # @return [GRANULARITY] The granularity of the interval for the stat such as :day, :hour, :minute, see {GRANULARITY}
    def interval_granularity
      self.class.granularity_from_interval_id(interval_id)
    end

    def attributes
      @attributes
    end

    def as_json(*args)
      attributes.as_json(*args).reject { |key, val| val.nil? }
    end

    private
    def raw_hash_object
      @raw_hash_object
    end

    def set_attributes_object(new_attributes)
      @attributes = IdiomaticRubyWrapper(new_attributes.clone.freeze)
    end
  end
end
