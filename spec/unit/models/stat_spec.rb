# encoding: utf-8
require 'spec_helper'
require 'shared/model_behaviour'

describe Ably::Models::Stat do
  include Ably::Modules::Conversions

  subject { Ably::Models::Stat }

  it_behaves_like 'a model', with_simple_attributes: %w(interval_id all inbound outbound persisted connections channels api_requests token_requests) do
    let(:model_args) { [] }
  end

  describe '#interval_granularity' do
    subject { Ably::Models::Stat.new(interval_id: '2004-02') }

    it 'returns the granularity of the interval_id' do
      expect(subject.interval_granularity).to eq(:month)
    end
  end

  describe '#interval_time' do
    subject { Ably::Models::Stat.new(interval_id: '2004-02-01:05:06') }

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
        expect(subject.from_interval_id('2014-02')).to eql(Time.new(2014, 2))
        expect(subject.from_interval_id('2014-02').utc_offset).to eql(0)
      end

      it 'converts a day interval_id 2014-02-03 into a Time object in UTC 0' do
        expect(subject.from_interval_id('2014-02-03')).to eql(Time.new(2014, 2, 3))
        expect(subject.from_interval_id('2014-02-03').utc_offset).to eql(0)
      end

      it 'converts an hour interval_id 2014-02-03:05 into a Time object in UTC 0' do
        expect(subject.from_interval_id('2014-02-03:05')).to eql(Time.new(2014, 2, 3, 5))
        expect(subject.from_interval_id('2014-02-03:05').utc_offset).to eql(0)
      end

      it 'converts a minute interval_id 2014-02-03:05:06 into a Time object in UTC 0' do
        expect(subject.from_interval_id('2014-02-03:05:06')).to eql(Time.new(2014, 2, 3, 5, 6))
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
