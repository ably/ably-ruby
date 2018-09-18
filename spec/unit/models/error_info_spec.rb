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
    subject { Ably::Models::ErrorInfo.new('code' => 44444) }

    it 'includes https://help.ably.io/error/[CODE] in the stringified object' do
      expect(subject.to_s).to include('https://help.ably.io/error/44444')
    end
  end
end
