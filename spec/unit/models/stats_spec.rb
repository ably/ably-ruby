# encoding: utf-8
require 'spec_helper'
require 'shared/model_behaviour'

describe Ably::Models::Stats do
  include Ably::Modules::Conversions

  subject { Ably::Models::Stats }

  %w(all persisted).each do |attribute|
    context "##{attribute} stats" do
      let(:data) do
        { attribute.to_sym => { messages: { count: 5 }, all: { data: 10 } } }
      end
      subject { Ably::Models::Stats.new(data.merge(interval_id: '2004-02')).public_send(attribute) }

      it 'returns a MessageTypes object' do
        expect(subject).to be_a(Ably::Models::Stats::MessageTypes)
      end

      it 'returns value for message counts' do
        expect(subject.messages.count).to eql(5)
      end

      it 'returns value for all data transferred' do
        expect(subject.all.data).to eql(10)
      end

      it 'returns zero for empty values' do
        expect(subject.presence.count).to eql(0)
      end

      it 'raises an exception for unknown attributes' do
        expect { subject.unknown }.to raise_error NoMethodError
      end

      %w(all presence messages).each do |type|
        context "##{type}" do
          it 'is a MessageCount object' do
            expect(subject.public_send(type)).to be_a(Ably::Models::Stats::MessageCount)
          end
        end
      end
    end
  end

  %w(inbound outbound).each do |direction|
    context "##{direction} stats" do
      let(:data) do
        {
          direction.to_sym => {
            realtime: { messages: { count: 5 }, presence: { data: 10 } },
            all: { messages: { count: 25 }, presence: { data: 210 } }
          }
        }
      end
      subject { Ably::Models::Stats.new(data.merge(interval_id: '2004-02')).public_send(direction) }

      it 'returns a MessageTraffic object' do
        expect(subject).to be_a(Ably::Models::Stats::MessageTraffic)
      end

      it 'returns value for realtime message counts' do
        expect(subject.realtime.messages.count).to eql(5)
      end

      it 'returns value for all presence data' do
        expect(subject.all.presence.data).to eql(210)
      end

      it 'raises an exception for unknown attributes' do
        expect { subject.unknown }.to raise_error NoMethodError
      end

      %w(realtime rest webhook all).each do |type|
        context "##{type}" do
          it 'is a MessageTypes object' do
            expect(subject.public_send(type)).to be_a(Ably::Models::Stats::MessageTypes)
          end
        end
      end
    end
  end

  context '#connections stats' do
    let(:data) do
      { connections: { tls: { opened: 5 }, all: { peak: 10 } } }
    end
    subject { Ably::Models::Stats.new(data.merge(interval_id: '2004-02')).connections }

    it 'returns a ConnectionTypes object' do
      expect(subject).to be_a(Ably::Models::Stats::ConnectionTypes)
    end

    it 'returns value for tls opened counts' do
      expect(subject.tls.opened).to eql(5)
    end

    it 'returns value for all peak connections' do
      expect(subject.all.peak).to eql(10)
    end

    it 'returns zero for empty values' do
      expect(subject.all.refused).to eql(0)
    end

    it 'raises an exception for unknown attributes' do
      expect { subject.unknown }.to raise_error NoMethodError
    end

    %w(tls plain all).each do |type|
      context "##{type}" do
        it 'is a ResourceCount object' do
          expect(subject.public_send(type)).to be_a(Ably::Models::Stats::ResourceCount)
        end
      end
    end
  end

  context '#channels stats' do
    let(:data) do
      { channels: { opened: 5, peak: 10 } }
    end
    subject { Ably::Models::Stats.new(data.merge(interval_id: '2004-02')).channels }

    it 'returns a ResourceCount object' do
      expect(subject).to be_a(Ably::Models::Stats::ResourceCount)
    end

    it 'returns value for opened counts' do
      expect(subject.opened).to eql(5)
    end

    it 'returns value for peak channels' do
      expect(subject.peak).to eql(10)
    end

    it 'returns zero for empty values' do
      expect(subject.refused).to eql(0)
    end

    it 'raises an exception for unknown attributes' do
      expect { subject.unknown }.to raise_error NoMethodError
    end

    %w(opened peak mean min refused).each do |type|
      context "##{type}" do
        it 'is a Integer object' do
          expect(subject.public_send(type)).to be_a(Integer)
        end
      end
    end
  end

  %w(api_requests token_requests).each do |request_type|
    context "##{request_type} stats" do
      let(:data) do
        {
          request_type.to_sym => { succeeded: 5, failed: 10 }
        }
      end
      subject { Ably::Models::Stats.new(data.merge(interval_id: '2004-02')).public_send(request_type) }

      it 'returns a RequestCount object' do
        expect(subject).to be_a(Ably::Models::Stats::RequestCount)
      end

      it 'returns value for succeeded' do
        expect(subject.succeeded).to eql(5)
      end

      it 'returns value for failed' do
        expect(subject.failed).to eql(10)
      end

      it 'raises an exception for unknown attributes' do
        expect { subject.unknown }.to raise_error NoMethodError
      end

      %w(succeeded failed refused).each do |type|
        context "##{type}" do
          it 'is a Integer object' do
            expect(subject.public_send(type)).to be_a(Integer)
          end
        end
      end
    end
  end

  describe '#interval_granularity' do
    subject { Ably::Models::Stats.new(interval_id: '2004-02') }

    it 'returns the granularity of the interval_id' do
      expect(subject.interval_granularity).to eq(:month)
    end
  end

  describe '#interval_time' do
    subject { Ably::Models::Stats.new(interval_id: '2004-02-01:05:06') }

    it 'returns a Time object representing the start of the interval' do
      expect(subject.interval_time.to_i).to eql(Time.new(2004, 02, 01, 05, 06, 00, '+00:00').to_i)
    end
  end

  context 'class methods' do
    describe '#to_interval_id' do
      context 'when time zone of time argument is UTC' do
        it 'converts time 2014-02-03:05:06 with granularity :month into 2014-02' do
          expect(subject.to_interval_id(Time.new(2014, 2, 1, 0, 0, 0, '+00:00'), :month)).to eql('2014-02')
        end

        it 'converts time 2014-02-03:05:06 with granularity :day into 2014-02-03' do
          expect(subject.to_interval_id(Time.new(2014, 2, 3, 0, 0, 0, '+00:00'), :day)).to eql('2014-02-03')
        end

        it 'converts time 2014-02-03:05:06 with granularity :hour into 2014-02-03:05' do
          expect(subject.to_interval_id(Time.new(2014, 2, 3, 5, 0, 0, '+00:00'), :hour)).to eql('2014-02-03:05')
        end

        it 'converts time 2014-02-03:05:06 with granularity :minute into 2014-02-03:05:06' do
          expect(subject.to_interval_id(Time.new(2014, 2, 3, 5, 6, 0, '+00:00'), :minute)).to eql('2014-02-03:05:06')
        end

        it 'fails with invalid granularity' do
          expect { subject.to_interval_id(Time.now, :invalid) }.to raise_error KeyError
        end

        it 'fails with invalid time' do
          expect { subject.to_interval_id(nil, :month) }.to raise_error ArgumentError
        end
      end

      context 'when time zone of time argument is +02:00' do
        it 'converts time 2014-02-03:06 with granularity :hour into 2014-02-03:04 at UTC +00:00' do
          expect(subject.to_interval_id(Time.new(2014, 2, 3, 6, 0, 0, '+02:00'), :hour)).to eql('2014-02-03:04')
        end
      end
    end

    describe '#from_interval_id' do
      it 'converts a month interval_id 2014-02 into a Time object in UTC 0' do
        expect(subject.from_interval_id('2014-02')).to eql(Time.gm(2014, 2))
        expect(subject.from_interval_id('2014-02').utc_offset).to eql(0)
      end

      it 'converts a day interval_id 2014-02-03 into a Time object in UTC 0' do
        expect(subject.from_interval_id('2014-02-03')).to eql(Time.gm(2014, 2, 3))
        expect(subject.from_interval_id('2014-02-03').utc_offset).to eql(0)
      end

      it 'converts an hour interval_id 2014-02-03:05 into a Time object in UTC 0' do
        expect(subject.from_interval_id('2014-02-03:05')).to eql(Time.gm(2014, 2, 3, 5))
        expect(subject.from_interval_id('2014-02-03:05').utc_offset).to eql(0)
      end

      it 'converts a minute interval_id 2014-02-03:05:06 into a Time object in UTC 0' do
        expect(subject.from_interval_id('2014-02-03:05:06')).to eql(Time.gm(2014, 2, 3, 5, 6))
        expect(subject.from_interval_id('2014-02-03:05:06').utc_offset).to eql(0)
      end

      it 'fails with an invalid interval_id 14-20' do
        expect { subject.from_interval_id('14-20') }.to raise_error ArgumentError
      end
    end

    describe '#granularity_from_interval_id' do
      it 'returns a :month interval_id for 2014-02' do
        expect(subject.granularity_from_interval_id('2014-02')).to eq(:month)
      end

      it 'returns a :day interval_id for 2014-02-03' do
        expect(subject.granularity_from_interval_id('2014-02-03')).to eq(:day)
      end

      it 'returns a :hour interval_id for 2014-02-03:05' do
        expect(subject.granularity_from_interval_id('2014-02-03:05')).to eq(:hour)
      end

      it 'returns a :minute interval_id for 2014-02-03:05:06' do
        expect(subject.granularity_from_interval_id('2014-02-03:05:06')).to eq(:minute)
      end

      it 'fails with an invalid interval_id 14-20' do
        expect { subject.granularity_from_interval_id('14-20') }.to raise_error ArgumentError
      end
    end
  end
end
