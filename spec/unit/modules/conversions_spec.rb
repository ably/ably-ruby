require 'spec_helper'

describe Ably::Modules::Conversions, :api_private do
  let(:class_with_module) { Class.new do; include Ably::Modules::Conversions; end }
  let(:subject) { class_with_module.new }
  before do
    # make method being tested public
    class_with_module.class_eval %{ public :#{method} }
  end

  context '#as_since_epoch' do
    let(:method) { :as_since_epoch }

    context 'with time' do
      let(:time) { Time.new }

      it 'converts to milliseconds by default' do
        expect(subject.as_since_epoch(time)).to be_within(1).of(time.to_f * 1_000)
      end

      it 'converted to seconds' do
        expect(subject.as_since_epoch(time, granularity: :s)).to eql(time.to_i)
      end
    end

    context 'with numeric' do
      it 'converts to integer' do
        expect(subject.as_since_epoch(1.01)).to eql(1)
      end

      it 'accepts integers' do
        expect(subject.as_since_epoch(1)).to eql(1)
      end
    end

    context 'with any other object' do
      it 'raises an exception' do
        expect { subject.as_since_epoch(Object.new) }.to raise_error ArgumentError
      end
    end
  end

  context '#as_time_from_epoch' do
    let(:method) { :as_time_from_epoch }
    let(:time) { Time.new }

    context 'with numeric' do
      let(:millisecond) { Time.new.to_f * 1_000 }
      let(:seconds) { Time.new.to_f }

      it 'converts to Time from milliseconds by default' do
        expect(subject.as_time_from_epoch(millisecond).to_f).to be_within(0.01).of(time.to_f)
      end

      it 'converts to Time from seconds' do
        expect(subject.as_time_from_epoch(seconds, granularity: :s).to_i).to eql(time.to_i)
      end
    end

    context 'with Time' do
      it 'leaves intact' do
        expect(subject.as_time_from_epoch(time)).to eql(time)
      end
    end

    context 'with any other object' do
      it 'raises an exception' do
        expect { subject.as_time_from_epoch(Object.new) }.to raise_error ArgumentError
      end
    end
  end
end
