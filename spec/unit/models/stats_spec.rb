# encoding: utf-8
require 'spec_helper'
require 'shared/model_behaviour'

describe Ably::Models::Stats do
  include Ably::Modules::Conversions

  subject { Ably::Models::Stats }

  describe '#interval_id' do
    it 'returns the interval ID string' do
      stat = subject.new(interval_id: '2024-02-03:15:05', unit: 'minute', entries: {}, schema: 'https://schemas.ably.com/json/app-stats-0.0.5.json')
      expect(stat.interval_id).to eql('2024-02-03:15:05')
    end
  end

  describe '#interval_time' do
    it 'returns a Time object representing the start of the interval' do
      stat = subject.new(interval_id: '2004-02-01:05:06', unit: 'minute', entries: {}, schema: 'https://schemas.ably.com/json/app-stats-0.0.5.json')
      expect(stat.interval_time.to_i).to eql(Time.new(2004, 02, 01, 05, 06, 00, '+00:00').to_i)
    end
  end

  describe '#unit' do
    it 'returns the unit from the JSON response' do
      stat = subject.new(interval_id: '2024-02', unit: 'month', entries: {}, schema: 'https://schemas.ably.com/json/app-stats-0.0.5.json')
      expect(stat.unit).to eql('month')
    end
  end

  describe '#entries' do
    it 'returns the entries hash' do
      entries = { 'messages.all.all.count' => 100, 'channels.peak' => 50 }
      stat = subject.new(interval_id: '2024-02', unit: 'month', entries: entries, schema: 'https://schemas.ably.com/json/app-stats-0.0.5.json')
      expect(stat.entries['messages.all.all.count']).to eql(100)
      expect(stat.entries['channels.peak']).to eql(50)
    end

    it 'returns an empty hash when entries is not present' do
      stat = subject.new(interval_id: '2024-02', unit: 'month', schema: 'https://schemas.ably.com/json/app-stats-0.0.5.json')
      expect(stat.entries).to eql({})
    end
  end

  describe '#in_progress' do
    it 'returns the in_progress string when present' do
      stat = subject.new(interval_id: '2024-02', unit: 'month', entries: {}, schema: 'https://schemas.ably.com/json/app-stats-0.0.5.json', inProgress: '2024-02-15:10:30')
      expect(stat.in_progress).to eql('2024-02-15:10:30')
    end

    it 'returns nil when not present' do
      stat = subject.new(interval_id: '2024-02', unit: 'month', entries: {}, schema: 'https://schemas.ably.com/json/app-stats-0.0.5.json')
      expect(stat.in_progress).to be_nil
    end
  end

  describe '#schema' do
    it 'returns the schema URI' do
      stat = subject.new(interval_id: '2024-02', unit: 'month', entries: {}, schema: 'https://schemas.ably.com/json/app-stats-0.0.5.json')
      expect(stat.schema).to eql('https://schemas.ably.com/json/app-stats-0.0.5.json')
    end
  end

  describe '#app_id' do
    it 'returns the application ID' do
      stat = subject.new(interval_id: '2024-02', unit: 'month', entries: {}, schema: 'https://schemas.ably.com/json/app-stats-0.0.5.json', appId: 'app123')
      expect(stat.app_id).to eql('app123')
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
