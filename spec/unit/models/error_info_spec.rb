require 'spec_helper'
require 'shared/model_behaviour'

describe Ably::Models::ErrorInfo do
  subject { Ably::Models::ErrorInfo }

  it_behaves_like 'a model', with_simple_attributes: %w(code status_code message) do
    let(:model_args) { [] }
  end

  context '#status' do
    subject { Ably::Models::ErrorInfo.new('statusCode' => 401) }
    it 'is an alias for #status_code' do
      expect(subject.status).to eql(subject.status_code)
      expect(subject.status).to eql(401)
    end
  end
end
