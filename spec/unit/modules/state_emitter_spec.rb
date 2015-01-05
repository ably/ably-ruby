require 'spec_helper'

describe Ably::Modules::StateEmitter do
  class ExampleStateWithEventEmitter
    include Ably::Modules::EventEmitter
    extend  Ably::Modules::Enum

    STATE = ruby_enum('STATE',
      :initializing,
      :connecting,
      :connected,
      :disconnected
    )
    include Ably::Modules::StateEmitter

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
      it 'returns true for #initializing? if state matches' do
        expect(subject.initializing?).to eql(true)
      end

      it 'returns false for #connecting? if state does not match' do
        expect(subject.connecting?).to eql(false)
      end
    end
  end

  context '#state STATE coercion', :api_private do
    it 'allows valid STATE values' do
      expect { subject.state = :connected }.to_not raise_error
    end

    it 'prevents invalid STATE values' do
      expect { subject.state = :invalid }.to raise_error KeyError
    end
  end

  context '#once_or_if', :api_private do
    let(:block_calls) { [] }
    let(:block) do
      proc do
        block_calls << Time.now
      end
    end

    it 'calls the block if in the provided state' do
      subject.once_or_if initial_state, &block
      expect(block_calls.count).to eql(1)
    end

    it 'calls the block when the state is reached' do
      subject.once_or_if :connected, &block
      expect(block_calls.count).to eql(0)

      subject.change_state :connected
      expect(block_calls.count).to eql(1)
    end

    it 'calls the block only once' do
      subject.once_or_if :connected, &block
      3.times do
        subject.change_state :connected
        subject.change_state :connecting
      end
      expect(block_calls.count).to eql(1)
    end
  end

  context '#once_state_changed', :api_private do
    let(:block_calls) { [] }
    let(:block) do
      proc do
        block_calls << Time.now
      end
    end

    it 'is not called if the state does not change' do
      subject.once_state_changed &block
      subject.change_state initial_state
      expect(block_calls.count).to eql(0)
    end

    it 'calls the block for any state change once' do
      subject.once_state_changed &block
      3.times do
        subject.change_state :connected
        subject.change_state :connecting
      end
      expect(block_calls.count).to eql(1)
    end
  end
end
