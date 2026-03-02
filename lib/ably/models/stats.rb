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
  # @spec TS12
  #
  class Stats
    include Ably::Modules::ModelCommon
    extend Ably::Modules::Enum

    # Describes the interval unit over which statistics are gathered.
    #
    # @spec TS12c
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
    # @param hash_object [Hash] object with the underlying stat details
    #
    def initialize(hash_object)
      @raw_hash_object = hash_object
      set_attributes_object hash_object
    end

    # The interval ID for this stats object.
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
    # @spec TS12p
    #
    # @return [Time]
    #
    def interval_time
      self.class.from_interval_id(interval_id)
    end

    # The unit of the interval, as provided by the API response.
    #
    # @spec TS12c
    #
    # @return [String]
    #
    def unit
      attributes[:unit]
    end

    # For entries that are still in progress, the last sub-interval included.
    #
    # @spec TS12q
    #
    # @return [String, nil]
    #
    def in_progress
      attributes[:in_progress]
    end

    # A flat dictionary of statistics entries with dot-separated keys.
    #
    # @spec TS12r
    #
    # @return [Hash]
    #
    def entries
      raw_entries = raw_hash_object[:entries] || raw_hash_object['entries']
      return {} unless raw_entries
      raw_entries.is_a?(Hash) ? raw_entries : {}
    end

    # The JSON schema URI for this stats object.
    #
    # @spec TS12s
    #
    # @return [String]
    #
    def schema
      attributes[:schema]
    end

    # The Ably application ID this stats object relates to.
    #
    # @spec TS12t
    #
    # @return [String]
    #
    def app_id
      attributes[:app_id]
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
