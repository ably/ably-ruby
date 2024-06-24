require 'spec_helper'
require 'ably/realtime/recovery_key_context'

describe Ably::Realtime::RecoveryKeyContext do

  context 'connection recovery key' do

    it 'should encode recovery key - RTN16i, RTN16f, RTN16j' do
      connection_key = 'key'
      msg_serial = 123
      channel_serials = {
        'channel1' => 'serial1',
        'channel2' => 'serial2'
      }
      recovery_context = Ably::Realtime::RecoveryKeyContext.new(connection_key, msg_serial, channel_serials)
      encoded_recovery_key = recovery_context.to_json
      expect(encoded_recovery_key).to eq "{\"connection_key\":\"key\",\"msg_serial\":123," <<
                                                "\"channel_serials\":{\"channel1\":\"serial1\",\"channel2\":\"serial2\"}}"
    end

    it 'should decode recovery key - RTN16i, RTN16f, RTN16j' do
      encoded_recovery_key = "{\"connection_key\":\"key\",\"msg_serial\":123," <<
                                     "\"channel_serials\":{\"channel1\":\"serial1\",\"channel2\":\"serial2\"}}"
      decoded_recovery_key = Ably::Realtime::RecoveryKeyContext.from_json(encoded_recovery_key)
      expect(decoded_recovery_key.connection_key).to eq("key")
      expect(decoded_recovery_key.msg_serial).to eq(123)
    end

    it 'should return nil for invalid recovery key - RTN16i, RTN16f, RTN16j' do
      encoded_recovery_key = "{\"invalid key\"}"
      decoded_recovery_key = Ably::Realtime::RecoveryKeyContext.from_json(encoded_recovery_key)
      expect(decoded_recovery_key).to be_nil
    end

  end
end
