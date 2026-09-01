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
  class Stats
    include Ably::Modules::ModelCommon
    extend Ably::Modules::Enum

    # Describes the interval unit over which statistics are gathered.
    #
    # MINUTE		Interval unit over which statistics are gathered as minutes.
    # HOUR		  Interval unit over which statistics are gathered as hours.
    # DAY		    Interval unit over which statistics are gathered as days.
    # MONTH		  Interval unit over which statistics are gathered as months.
    #
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

      # Returns the {Symbol} determined from the interval_id
      # @example
      #   Stats.granularity_from_interval_id('2015-01-01:10') # => :hour
      #
      # @param interval_id [String]
      #
      # @return [Symbol]
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

    # A {Ably::Models::Stats::MessageTypes} object containing the aggregate count of all message stats.
    #
    # @spec TS12e
    #
    # @return [Stats::MessageTypes]
    #
    def all
      @all ||= Stats::MessageTypes.new(attributes[:all])
    end

    # A {Ably::Models::Stats::MessageTraffic} object containing the aggregate count of inbound message stats.
    #
    # @spec TS12f
    #
    # @return [Ably::Models::Stats::MessageTraffic]
    #
    def inbound
      @inbound ||= Stats::MessageTraffic.new(attributes[:inbound])
    end

    # A {Ably::Models::Stats::MessageTraffic} object containing the aggregate count of outbound message stats.
    #
    # @spec TS12g
    #
    # @return [Ably::Models::Stats::MessageTraffic]
    #
    def outbound
      @outbound ||= Stats::MessageTraffic.new(attributes[:outbound])
    end

    # A {Ably::Models::Stats::MessageTraffic} object containing the aggregate count of persisted message stats.
    #
    # @spec TS12h
    #
    # @return [Ably::Models::Stats::MessageTraffic]
    #
    def persisted
      @persisted ||= Stats::MessageTypes.new(attributes[:persisted])
    end

    # A {Ably::Models::Stats::ConnectionTypes} object containing a breakdown of connection related stats, such as min, mean and peak connections.
    #
    # @spec TS12i
    #
    # @return [Ably::Models::Stats::ConnectionTypes]
    #
    def connections
      @connections ||= Stats::ConnectionTypes.new(attributes[:connections])
    end

    # A {Ably::Models::Stats::ResourceCount} object containing a breakdown of connection related stats, such as min, mean and peak connections.
    #
    # @spec TS12j
    #
    # @return [Ably::Models::Stats::ResourceCount]
    #
    def channels
      @channels ||= Stats::ResourceCount.new(attributes[:channels])
    end

    # A {Ably::Models::Stats::RequestCount} object containing a breakdown of API Requests.
    #
    # @spec TS12k
    #
    # @return [Ably::Models::Stats::RequestCount]
    #
    def api_requests
      @api_requests ||= Stats::RequestCount.new(attributes[:api_requests])
    end

    # A {Ably::Models::Stats::RequestCount} object containing a breakdown of Ably Token requests.
    #
    # @spec TS12l
    #
    # @return [Ably::Models::Stats::RequestCount]
    #
    def token_requests
      @token_requests ||= Stats::RequestCount.new(attributes[:token_requests])
    end

    # The UTC time at which the time period covered begins. If unit is set to minute this will be in
    # the format YYYY-mm-dd:HH:MM, if hour it will be YYYY-mm-dd:HH, if day it will be YYYY-mm-dd:00
    # and if month it will be YYYY-mm-01:00.
    #
    # @spec TS12a
    #
    # @return [String]
    #
    def interval_id
      attributes.fetch(:interval_id)
    end

    # Represents the intervalId as a time object.
    #
    # @spec TS12b
    #
    # @return [Time]
    #
    def interval_time
      self.class.from_interval_id(interval_id)
    end

    # The length of the interval the stats span. Values will be a [StatsIntervalGranularity]{@link StatsIntervalGranularity}.
    #
    # @spec TS12c
    #
    # @return [GRANULARITY] The granularity of the interval for the stat such as :day, :hour, :minute, see {GRANULARITY}
    #
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
