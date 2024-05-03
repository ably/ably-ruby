require 'spec_helper'
require 'ably/realtime/recovery_key_context'

describe Ably::Realtime::RecoveryKeyContext do

  context 'recovery context' do
    let(:recovery_context) do
      connection_key = 'key'
      msg_serial = 123
      channel_serials = {
        'channel1' => 'serial1',
        'channel2' => 'serial2'
      }
      return Ably::Realtime::RecoveryKeyContext.new(connection_key, msg_serial, channel_serials)
    end

    it 'should encode recovery key context' do
      encoded_recovery_key = recovery_context.encode
    end
  end
end
