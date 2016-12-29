# encoding: utf-8

shared_examples 'a safe Deferrable' do
  let(:logger) { instance_double('Logger') }
  let(:arguments) { [random_str] }
  let(:errback_calls) { [] }
  let(:success_calls) { [] }
  let(:exception) { StandardError.new("Intentional error") }

  before do
    allow(subject).to receive(:logger).and_return(logger)
  end

  context '#errback' do
    it 'adds a callback that is called when #fail is called' do
      subject.errback do |*args|
        expect(args).to eql(arguments)
      end
      subject.fail(*arguments)
    end

    it 'catches exceptions in the callback and logs the error to the logger' do
      expect(subject.send(:logger)).to receive(:error) do |*args, &block|
        expect(args.concat([block ? block.call : nil]).join(',')).to match(/#{exception.message}/)
      end
      subject.errback do
        raise exception
      end
      subject.fail
    end
  end

  context '#fail' do
    it 'calls the callbacks defined with #errback, but not the ones added for success #callback' do
      3.times do
        subject.errback  { errback_calls << true }
        subject.callback { success_calls << true }
      end
      subject.fail(*arguments)
      expect(errback_calls.count).to eql(3)
      expect(success_calls.count).to eql(0)
    end
  end

  context '#callback' do
    it 'adds a callback that is called when #succed is called' do
      subject.callback do |*args|
        expect(args).to eql(arguments)
      end
      subject.succeed(*arguments)
    end

    it 'catches exceptions in the callback and logs the error to the logger' do
      expect(subject.send(:logger)).to receive(:error) do |*args, &block|
        expect(args.concat([block ? block.call : nil]).join(',')).to match(/#{exception.message}/)
      end
      subject.callback do
        raise exception
      end
      subject.succeed
    end
  end

  context '#succeed' do
    it 'calls the callbacks defined with #callback, but not the ones added for #errback' do
      3.times do
        subject.errback  { errback_calls << true }
        subject.callback { success_calls << true }
      end
      subject.succeed(*arguments)
      expect(success_calls.count).to eql(3)
      expect(errback_calls.count).to eql(0)
    end
  end
end
