require 'spec_helper'
require 'support/model_helper'

describe Ably::Realtime::Models::ErrorInfo do
  subject { Ably::Realtime::Models::ErrorInfo }

  it_behaves_like 'a realtime model', with_simple_attributes: %w(code status_code message) do
    let(:model_args) { [] }
  end

  context '#status' do
    subject { Ably::Realtime::Models::ErrorInfo.new('statusCode' => 401) }
    it 'is an alias for #status_code' do
      expect(subject.status).to eql(subject.status_code)
      expect(subject.status).to eql(401)
    end
  end
end
