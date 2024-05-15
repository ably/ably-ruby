require 'json'
# frozen_string_literal: true

module Ably
  module Realtime
    class RecoveryKeyContext
      attr_reader :connection_key
      attr_reader :msg_serial
      attr_reader :channel_serials

      def initialize(connection_key, msg_serial, channel_serials)
        @connection_key = connection_key
        @msg_serial = msg_serial
        @channel_serials = channel_serials
      end

      def to_json
        {'connection_key' => @connection_key, 'msg_serial' => @msg_serial, 'channel_serials' => @channel_serials }.to_json
      end

      def self.from_json(obj, logger = nil)
        begin
          data = JSON.load obj
          self.new data['connection_key'], data['msg_serial'], data['channel_serials']
        rescue => e
          unless logger.nil?
            logger.warn "unable to decode recovery key, found error #{e}"
          end
          return nil
        end
      end

    end
  end
end
