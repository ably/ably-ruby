# encoding: utf-8
require 'spec_helper'
require 'shared/model_behaviour'

describe Ably::Models::ProtocolMessage do
  include Ably::Modules::Conversions
  subject { Ably::Models::ProtocolMessage }

  def new_protocol_message(options)
    subject.new({ action: 1 }.merge(options))
  end

  # TR4n, TR4b, TR4c, TR4d
  it_behaves_like 'a model',
    with_simple_attributes: %w(id channel channel_serial connection_id),
    base_model_options: { action: 1 } do

    let(:model_args) { [] }
  end

  context 'initializer action coercion', :api_private do
    it 'ignores actions that are Integers' do
      protocol_message = subject.new(action: 14)
      expect(protocol_message.attributes[:action]).to eql(14)
    end

    it 'converts actions to Integers if a symbol' do
      protocol_message = subject.new(action: :message)
      expect(protocol_message.attributes[:action]).to eql(15)
    end

    it 'converts actions to Integers if a ACTION' do
      protocol_message = subject.new(action: Ably::Models::ProtocolMessage::ACTION.Message)
      expect(protocol_message.attributes[:action]).to eql(15)
    end

    it 'raises an argument error if nil' do
      expect { subject.new({}) }.to raise_error(ArgumentError)
    end
  end

  context 'attributes' do
    let(:unique_value) { random_str }

    context 'Java naming', :api_private do
      let(:protocol_message) { new_protocol_message(channelSerial: unique_value) }

      it 'converts the attribute to ruby symbol naming convention' do
        expect(protocol_message.channel_serial).to eql(unique_value)
      end
    end

    context '#action', :api_private do
      let(:protocol_message) { new_protocol_message(action: 14) }

      it 'returns an Enum that behaves like a symbol' do
        expect(protocol_message.action).to eq(:presence)
      end

      it 'returns an Enum that behaves like a Numeric' do
        expect(protocol_message.action).to eq(14)
      end

      it 'returns an Enum that behaves like a String' do
        expect(protocol_message.action).to eq('Presence')
      end

      it 'returns an Enum that matchdes the ACTION constant' do
        expect(protocol_message.action).to eql(Ably::Models::ProtocolMessage::ACTION.Presence)
      end
    end

    context '#timestamp' do
      let(:protocol_message) { new_protocol_message(timestamp: as_since_epoch(Time.now)) }
      it 'retrieves attribute :timestamp as Time object' do
        expect(protocol_message.timestamp).to be_a(Time)
        expect(protocol_message.timestamp.to_i).to be_within(1).of(Time.now.to_i)
      end
    end

    context '#count' do
      context 'when missing' do
        let(:protocol_message) { new_protocol_message({}) }
        it 'is 1' do
          expect(protocol_message.count).to eql(1)
        end
      end

      context 'when non numeric' do
        let(:protocol_message) { new_protocol_message(count: 'A') }
        it 'is 1' do
          expect(protocol_message.count).to eql(1)
        end
      end

      context 'when greater than 1' do
        let(:protocol_message) { new_protocol_message(count: '666') }
        it 'is the value of count' do
          expect(protocol_message.count).to eql(666)
        end
      end
    end

    context '#message_serial' do
      let(:protocol_message) { new_protocol_message(msg_serial: "55") }
      it 'converts :msg_serial to an Integer' do
        expect(protocol_message.message_serial).to be_a(Integer)
        expect(protocol_message.message_serial).to eql(55)
      end
    end

    context '#has_message_serial?' do
      context 'without msg_serial' do
        let(:protocol_message) { new_protocol_message({}) }

        it 'returns false' do
          expect(protocol_message.has_message_serial?).to eql(false)
        end
      end

      context 'with msg_serial' do
        let(:protocol_message) { new_protocol_message(msg_serial: "55") }

        it 'returns true' do
          expect(protocol_message.has_message_serial?).to eql(true)
        end
      end
    end

    context '#flags (#TR4i)' do
      context 'when nil' do
        let(:protocol_message) { new_protocol_message({}) }

        it 'is zero' do
          expect(protocol_message.flags).to eql(0)
        end
      end

      context 'when numeric' do
        let(:protocol_message) { new_protocol_message(flags: '25') }

        it 'is an Integer' do
          expect(protocol_message.flags).to eql(25)
        end
      end

      context 'when presence flag present' do
        let(:protocol_message) { new_protocol_message(flags: 1) }

        it '#has_presence_flag? is true' do
          expect(protocol_message.has_presence_flag?).to be_truthy
        end

        it '#has_channel_resumed_flag? is false' do
          expect(protocol_message.has_channel_resumed_flag?).to be_falsey
        end
      end

      context 'when channel resumed flag present' do
        let(:protocol_message) { new_protocol_message(flags: 4) }

        it '#has_channel_resumed_flag? is true' do
          expect(protocol_message.has_channel_resumed_flag?).to be_truthy
        end

        it '#has_presence_flag? is false' do
          expect(protocol_message.has_presence_flag?).to be_falsey
        end
      end

      context 'when attach resumed flag' do
        context 'flags is 34' do
          let(:protocol_message) { new_protocol_message(flags: 34) }

          it '#has_attach_resume_flag? is true' do
            expect(protocol_message.has_attach_resume_flag?).to be_truthy
          end

          it '#has_attach_presence_flag? is false' do
            expect(protocol_message.has_attach_presence_flag?).to be_falsey
          end
        end

        context 'flags is 0' do
          let(:protocol_message) { new_protocol_message(flags: 0) }

          it 'should raise an exception if flags is a float number' do
            expect(protocol_message.has_attach_resume_flag?).to be_falsy
          end
        end
      end

      context 'when channel resumed and presence flags present' do
        let(:protocol_message) { new_protocol_message(flags: 5) }

        it '#has_channel_resumed_flag? is true' do
          expect(protocol_message.has_channel_resumed_flag?).to be_truthy
        end

        it '#has_presence_flag? is true' do
          expect(protocol_message.has_presence_flag?).to be_truthy
        end
      end

      context 'when has another future flag' do
        let(:protocol_message) { new_protocol_message(flags: 2) }

        it '#has_presence_flag? is false' do
          expect(protocol_message.has_presence_flag?).to be_falsey
        end

        it '#has_backlog_flag? is true' do
          expect(protocol_message.has_backlog_flag?).to be_truthy
        end
      end
    end

    context '#params (#RTL4k1)' do
      let(:params) do
        { foo: :bar }
      end

      context 'when present' do
        specify do
          expect(new_protocol_message({ params: params }).params).to eq(params)
        end
      end

      context 'when empty' do
        specify do
          expect(new_protocol_message({}).params).to eq({})
        end
      end
    end

    context '#serial' do
      context 'with underlying msg_serial' do
        let(:protocol_message) { new_protocol_message(msg_serial: "55") }
        it 'converts :msg_serial to an Integer' do
          expect(protocol_message.message_serial).to be_a(Integer)
          expect(protocol_message.message_serial).to eql(55)
        end
      end
    end

    context '#has_serial?' do
      context 'without msg_serial' do
        let(:protocol_message) { new_protocol_message({}) }

        it 'returns false' do
          expect(protocol_message.has_serial?).to eql(false)
        end
      end

      context 'with msg_serial' do
        let(:protocol_message) { new_protocol_message(msg_serial: "55") }

        it 'returns true' do
          expect(protocol_message.has_serial?).to eql(true)
        end
      end
    end

    context '#error' do
      context 'with no error attribute' do
        let(:protocol_message) { new_protocol_message(action: 1) }

        it 'returns nil' do
          expect(protocol_message.error).to be_nil
        end
      end

      context 'with nil error' do
        let(:protocol_message) { new_protocol_message(error: nil) }

        it 'returns nil' do
          expect(protocol_message.error).to be_nil
        end
      end

      context 'with error' do
        let(:protocol_message) { new_protocol_message(error: { message: 'test_error' }) }

        it 'returns a valid ErrorInfo object' do
          expect(protocol_message.error).to be_a(Ably::Models::ErrorInfo)
          expect(protocol_message.error.message).to eql('test_error')
        end
      end
    end

    context '#messages (#TR4k)' do
      let(:protocol_message) { new_protocol_message(messages: [{ name: 'test' }]) }

      it 'contains Message objects' do
        expect(protocol_message.messages.count).to eql(1)
        expect(protocol_message.messages.first).to be_a(Ably::Models::Message)
        expect(protocol_message.messages.first.name).to eql('test')
      end
    end

    context '#messages (#RTL21)' do
      let(:protocol_message) do
        new_protocol_message(messages: [{ name: 'test1' }, { name: 'test2' }, { name: 'test3' }])
      end

      before do
        message = Ably::Models::Message(name: 'test4')
        message.assign_to_protocol_message(protocol_message)
        protocol_message.add_message(message)
      end

      it 'contains Message objects in ascending order' do
        expect(protocol_message.messages.count).to eql(4)
        protocol_message.messages.each_with_index do |message, index|
          expect(message.protocol_message_index).to eql(index)
          expect(message.name).to include('test')
        end
      end
    end

    context '#presence (#TR4l)' do
      let(:protocol_message) { new_protocol_message(presence: [{ action: 1, data: 'test' }]) }

      it 'contains PresenceMessage objects' do
        expect(protocol_message.presence.count).to eql(1)
        expect(protocol_message.presence.first).to be_a(Ably::Models::PresenceMessage)
        expect(protocol_message.presence.first.data).to eql('test')
      end
    end

    context '#message_size (#TO3l8)' do
      context 'on presence' do
        let(:protocol_message) do
          new_protocol_message(presence: [{ action: 1, data: 'test342343', client_id: 'sdf' }])
        end

        it 'should return 13 bytes (sum in bytes: data and client_id)' do
          expect(protocol_message.message_size).to eq(13)
        end
      end

      context 'on message' do
        let(:protocol_message) do
          new_protocol_message(messages: [{ action: 1, unknown: 'test', data: 'test342343', client_id: 'sdf', name: 'sf23ewrew', extras: { time: Time.now, time_zone: 'UTC' } }])
        end

        it 'should return 76 bytes (sum in bytes: data, client_id, name, extras)' do
          expect(protocol_message.message_size).to eq(76)
        end
      end
    end

    context '#connection_details (#TR4o)' do
      let(:connection_details) { protocol_message.connection_details }

      context 'with a JSON value' do
        let(:protocol_message) { new_protocol_message(connectionDetails: { clientId: '1', connectionKey: 'key' }) }

        it 'contains a ConnectionDetails object' do
          expect(connection_details).to be_a(Ably::Models::ConnectionDetails)
        end

        it 'contains the attributes from the JSON connectionDetails' do
          expect(connection_details.client_id).to eql('1')
          expect(connection_details.connection_key).to eql('key')
        end
      end

      context 'without a JSON value' do
        let(:protocol_message) { new_protocol_message({}) }

        it 'contains an empty ConnectionDetails object' do
          expect(connection_details).to be_a(Ably::Models::ConnectionDetails)
          expect(connection_details.client_id).to eql(nil)
          expect(connection_details.connection_key).to eql(nil)
        end
      end
    end

    context '#auth (#TR4p)' do
      let(:auth) { protocol_message.auth }

      context 'with a JSON value' do
        let(:protocol_message) { new_protocol_message(auth: { accesstoken: 'foo' }) }

        it 'contains a AuthDetails object' do
          expect(auth).to be_a(Ably::Models::AuthDetails)
        end

        it 'contains the attributes from the JSON auth details' do
          expect(auth.access_token).to eql('foo')
        end
      end

      context 'without a JSON value' do
        let(:protocol_message) { new_protocol_message({}) }

        it 'contains an empty AuthDetails object' do
          expect(auth).to be_a(Ably::Models::AuthDetails)
          expect(auth.access_token).to eql(nil)
        end
      end
    end
  end

  context '#to_json', :api_private do
    let(:json_object) { JSON.parse(model.to_json) }
    let(:message1) { { 'name' => 'event1', 'clientId' => 'joe', 'timestamp' => as_since_epoch(Time.now) } }
    let(:message2) { { 'name' => 'event2', 'clientId' => 'joe', 'timestamp' => as_since_epoch(Time.now) } }
    let(:message3) { { 'name' => 'event3', 'clientId' => 'joe', 'timestamp' => as_since_epoch(Time.now) } }
    let(:attached_action) { Ably::Models::ProtocolMessage::ACTION.Attached }
    let(:message_action) { Ably::Models::ProtocolMessage::ACTION.Message }

    context 'with valid data' do
      let(:model) { new_protocol_message({ :action => attached_action, :channelSerial => 'unique', messages: [message1, message2, message3] }) }

      it 'converts the attribute back to Java mixedCase notation using string keys' do
        expect(json_object["channelSerial"]).to eql('unique')
      end

      it 'populates the messages' do
        expect(json_object["messages"][0]).to include(message1)
        expect(json_object["messages"][1]).to include(message2)
        expect(json_object["messages"][2]).to include(message3)
      end
    end

    context 'with missing msg_serial for ack message' do
      let(:model) { new_protocol_message({ :action => message_action }) }

      it 'it raises an exception' do
        expect { model.to_json }.to raise_error TypeError, /msg_serial.*missing/
      end
    end

    context 'is aliased by #to_s' do
      let(:model) { new_protocol_message({ :action => attached_action, :channelSerial => 'unique', messages: [message1, message2, message3], :timestamp => as_since_epoch(Time.now) }) }

      specify do
        expect(json_object).to eql(JSON.parse("#{model}"))
      end
    end
  end

  context '#to_msgpack', :api_private do
    let(:model)    { new_protocol_message({ :connectionSerial => 'unique', messages: [message1, message2, message3] }) }
    let(:message1)  { { 'name' => 'event1', 'clientId' => 'joe', 'timestamp' => as_since_epoch(Time.now) } }
    let(:message2)  { { 'name' => 'event2', 'clientId' => 'joe', 'timestamp' => as_since_epoch(Time.now) } }
    let(:message3)  { { 'name' => 'event3', 'clientId' => 'joe', 'timestamp' => as_since_epoch(Time.now) } }
    let(:packed)   { model.to_msgpack }
    let(:unpacked) { MessagePack.unpack(packed) }

    it 'returns a unpackable msgpack object' do
      expect(unpacked['connectionSerial']).to eq('unique')
      expect(unpacked['messages'][0]['name']).to eq('event1')
      expect(unpacked['messages'][1]['name']).to eq('event2')
      expect(unpacked['messages'][2]['name']).to eq('event3')
    end
  end
end
