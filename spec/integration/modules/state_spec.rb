require 'spec_helper'

describe Ably::Modules::State do
  class ExampleStateWithEventEmitter
    include Ably::Modules::EventEmitter
    extend  Ably::Modules::Enum

    STATE = ruby_enum('STATE',
      :initializing,
      :connecting,
      :connected,
      :disconnected
    )
    include Ably::Modules::State

    def initialize
      @state = :initializing
    end
  end

  let(:initial_state) { :initializing }

  subject { ExampleStateWithEventEmitter.new }

  specify '#state returns current state' do
    expect(subject.state).to eq(:initializing)
  end

  specify '#state= sets current state' do
    expect { subject.state = :connecting }.to change { subject.state }.to(:connecting)
  end

  specify '#change_state sets current state' do
    expect { subject.change_state :connecting }.to change { subject.state }.to(:connecting)
  end

  context '#change_state with arguments' do
    let(:args) { [5,3,1] }
    let(:callback_status) { { called: false } }

    it 'passes the arguments through to the triggered callback' do
      subject.on(:connecting) do |*callback_args|
        expect(callback_args).to eql(args)
        callback_status[:called] = true
      end
      expect { subject.change_state :connecting, *args }.to change { subject.state }.to(:connecting)
      expect(callback_status).to eql(called: true)
    end
  end

  context '#state?' do
    it 'returns true if state matches' do
      expect(subject.state?(initial_state)).to eql(true)
    end

    it 'returns false if state does not match' do
      expect(subject.state?(:connecting)).to eql(false)
    end

    context 'and convenience predicates for states' do
      it 'returns true if state matches' do
        expect(subject.initializing?).to eql(true)
      end

      it 'returns false if state does not match' do
        expect(subject.connecting?).to eql(false)
      end
    end
  end

  context '#state STATE coercion' do
    it 'allows valid STATE values' do
      expect { subject.state = :connected }.to_not raise_error
    end

    it 'prevents invalid STATE values' do
      expect { subject.state = :invalid }.to raise_error KeyError
    end
  end
end
