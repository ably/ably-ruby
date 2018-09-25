require 'spec_helper'
require 'shared/model_behaviour'

describe Ably::Models::ErrorInfo do
  subject { Ably::Models::ErrorInfo }

  context '#TI1, #TI4' do
    it_behaves_like 'a model', with_simple_attributes: %w(code status_code href message) do
      let(:model_args) { [] }
    end
  end

  context '#status #TI1, #TI2' do
    subject { Ably::Models::ErrorInfo.new('statusCode' => 401) }
    it 'is an alias for #status_code' do
      expect(subject.status).to eql(subject.status_code)
      expect(subject.status).to eql(401)
    end
  end

  context 'log entries container help link #TI5' do
    context 'without an error code' do
      subject { Ably::Models::ErrorInfo.new('statusCode' => 401) }

      it 'does not include the help URL' do
        expect(subject.to_s.scan(/help\.ably\.io/)).to be_empty
      end
    end

    context 'with a specified error code' do
      subject { Ably::Models::ErrorInfo.new('code' => 44444) }

      it 'includes https://help.ably.io/error/[CODE] in the stringified object' do
        expect(subject.to_s).to include('https://help.ably.io/error/44444')
      end
    end

    context 'with an error code and an href attribute' do
      subject { Ably::Models::ErrorInfo.new('code' => 44444, 'href' => 'http://foo.bar.com/') }

      it 'includes the specified href in the stringified object' do
        expect(subject.to_s).to include('http://foo.bar.com/')
        expect(subject.to_s).to_not include('https://help.ably.io/error/44444')
      end
    end

    context 'with an error code and a message with the same error URL' do
      subject { Ably::Models::ErrorInfo.new('message' => 'error https://help.ably.io/error/44444', 'code' => 44444) }

      it 'includes the specified error URL only once in the stringified object' do
        expect(subject.to_s.scan(/help.ably.io/).length).to eql(1)
      end
    end

    context 'with an error code and a message with a different error URL' do
      subject { Ably::Models::ErrorInfo.new('message' => 'error https://help.ably.io/error/123123', 'code' => 44444) }

      it 'includes the specified error URL from the message and the error code URL in the stringified object' do
        puts subject.to_s
        expect(subject.to_s.scan(/help.ably.io/).length).to eql(2)
        expect(subject.to_s.scan(%r{error/123123}).length).to eql(1)
        expect(subject.to_s.scan(%r{error/44444}).length).to eql(1)
      end
    end
  end
end
