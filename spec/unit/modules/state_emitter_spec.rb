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

    def initialize(logger)
      @state = :initializing
      @logger = logger
    end

    attr_reader :logger
  end

  let(:initial_state) { :initializing }

  subject { ExampleStateWithEventEmitter.new(double('Logger').as_null_object) }

  specify '#state returns current state' do
    expect(subject.state).to eq(:initializing)
  end

  specify '#state= sets current state' do
    expect { subject.state = :connecting }.to change { subject.state.to_sym }.to(:connecting)
  end

  specify '#change_state sets current state' do
    expect { subject.change_state :connecting }.to change { subject.state.to_sym }.to(:connecting)
  end

  context '#change_state with arguments' do
    let(:args) { [5,3,1] }
    let(:callback_status) { { called: false } }

    it 'passes the arguments through to the executed callback' do
      subject.on(:connecting) do |*callback_args|
        expect(callback_args).to eql(args)
        callback_status[:called] = true
      end
      expect { subject.change_state :connecting, *args }.to change { subject.state.to_sym }.to(:connecting)
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
    context 'without :else option block' do
      let(:block_calls) { [] }
      let(:block) do
        lambda do
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

    context 'with an array of targets' do
      let(:block_calls) { [] }
      let(:block) do
        lambda do
          block_calls << Time.now
        end
      end

      it 'calls the block if in the provided state' do
        subject.once_or_if [initial_state, :connecting], &block
        expect(block_calls.count).to eql(1)
      end

      it 'calls the block when one of the states is reached' do
        subject.once_or_if [:connecting, :connected], &block
        expect(block_calls.count).to eql(0)

        subject.change_state :connected
        expect(block_calls.count).to eql(1)
      end

      it 'calls the block only once' do
        subject.once_or_if [:connecting, :connected], &block
        expect(block_calls.count).to eql(0)

        3.times do
          subject.change_state :connected
          subject.change_state :connecting
        end
        expect(block_calls.count).to eql(1)
      end

      it 'does not remove all blocks on success' do
        allow(subject).to receive(:off) do |&block|
          raise 'Should not receive a nil block' if block.nil?
        end

        subject.once_or_if(:connected) { }
        subject.change_state :connected
      end
    end

    context 'with :else option block', :api_private do
      let(:success_calls) { [] }
      let(:success_block) do
        lambda do
          success_calls << Time.now
        end
      end

      let(:failure_calls) { [] }
      let(:failure_block) do
        lambda do |*args|
          failure_calls << args
        end
      end

      let(:target_state) { :connected }

      before do
        subject.once_or_if target_state, else: failure_block, &success_block
      end

      context 'blocks' do
        specify 'are not called if the state does not change' do
          subject.change_state initial_state
          expect(success_calls.count).to eql(0)
          expect(failure_calls.count).to eql(0)
        end
      end

      context 'success block' do
        it 'is called once target_state is reached' do
          subject.change_state target_state
          expect(success_calls.count).to eql(1)
        end

        it 'is never called again once target_state is reached' do
          subject.change_state target_state
          subject.change_state :connecting
          subject.change_state target_state
          expect(success_calls.count).to eql(1)
        end

        it 'is never called after failure block was called' do
          subject.change_state :connecting
          subject.change_state target_state
          expect(success_calls.count).to eql(0)
          expect(failure_calls.count).to eql(1)
        end
      end

      context 'failure block' do
        it 'is called once a state other than target_state is reached' do
          subject.change_state :connecting
          expect(failure_calls.count).to eql(1)
        end

        it 'is never called again once the block has been called previously' do
          subject.change_state :connecting
          subject.change_state target_state
          subject.change_state :connecting
          expect(failure_calls.count).to eql(1)
        end

        it 'is never called after success block was called' do
          subject.change_state target_state
          subject.change_state :connecting
          expect(failure_calls.count).to eql(0)
          expect(success_calls.count).to eql(1)
        end

        it 'has arguments from the error state' do
          subject.change_state :disconnected, 1, 2
          expect(failure_calls.count).to eql(1)
          expect(failure_calls.first).to contain_exactly(1, 2)
        end
      end
    end

    context 'state change arguments' do
      let(:arguments) { [1,2,3] }

      specify 'are passed to success blocks' do
        subject.once_or_if(:connected) do |*arguments|
          expect(arguments).to eql(arguments)
        end
        subject.change_state :connected, *arguments
      end

      specify 'are passed to else blocks' do
        else_block = lambda { |arguments| expect(arguments).to eql(arguments) }
        subject.once_or_if(:connected, else: else_block) do
          raise 'Success should not be called'
        end
        subject.change_state :connecting, *arguments
      end
    end

    context 'with blocks that raise exceptions' do
      let(:success_block) do
        lambda { raise 'Success exception' }
      end

      let(:failure_block) do
        lambda { raise 'Failure exception' }
      end

      let(:target_state) { :connected }

      before do
        subject.once_or_if target_state, else: failure_block, &success_block
      end

      context 'success block' do
        it 'catches exceptions in the provided block, logs the error and continues' do
          expect(subject.logger).to receive(:error) do |*args, &block|
            expect(args.concat([block ? block.call : nil]).join(',')).to match(/Success exception/)
          end
          subject.change_state target_state
        end
      end

      context 'failure block' do
        it 'catches exceptions in the provided block, logs the error and continues' do
          expect(subject.logger).to receive(:error) do |*args, &block|
            expect(args.concat([block ? block.call : nil]).join(',')).to match(/Failure exception/)
          end
          subject.change_state :connecting
        end
      end
    end
  end

  context '#unsafe_once_or_if', :api_private do
    let(:target_state) { :connected }

    let(:success_block) do
      lambda { raise 'Success exception' }
    end

    let(:failure_block) do
      lambda { raise 'Failure exception' }
    end

    before do
      subject.unsafe_once_or_if target_state, else: failure_block, &success_block
    end

    context 'success block' do
      it 'catches exceptions in the provided block, logs the error and continues' do
        expect { subject.change_state target_state }.to raise_error(/Success exception/)
      end
    end

    context 'failure block' do
      it 'catches exceptions in the provided block, logs the error and continues' do
        expect { subject.change_state :connecting }.to raise_error(/Failure exception/)
      end
    end
  end

  context '#once_state_changed', :api_private do
    let(:block_calls) { [] }
    let(:block) do
      lambda do |*args|
        block_calls << args
      end
    end

    it 'is not called if the state does not change' do
      subject.once_state_changed(&block)
      subject.change_state initial_state
      expect(block_calls.count).to eql(0)
    end

    it 'calls the block for any state change once' do
      subject.once_state_changed(&block)
      3.times do
        subject.change_state :connected
        subject.change_state :connecting
      end
      expect(block_calls.count).to eql(1)
    end

    it 'emits arguments to the block' do
      subject.once_state_changed(&block)
      subject.change_state :connected, 1, 2
      expect(block_calls.count).to eql(1)
      expect(block_calls.first).to contain_exactly(1, 2)
    end

    it 'catches exceptions in the provided block, logs the error and continues' do
      subject.once_state_changed { raise 'Intentional exception' }
      expect(subject.logger).to receive(:error) do |*args, &block|
        expect(args.concat([block ? block.call : nil]).join(',')).to match(/Intentional exception/)
      end
      subject.change_state :connected
    end
  end

  context '#unsafe_once_state_changed', :api_private do
    it 'does not catch exceptions in the provided block' do
      subject.unsafe_once_state_changed { raise 'Intentional exception' }
      expect { subject.change_state :connected }.to raise_error(/Intentional exception/)
    end
  end
end
