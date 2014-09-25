require 'spec_helper'
require 'support/model_helper'

describe Ably::Realtime::Models::ErrorInfo do
  subject { Ably::Realtime::Models::ErrorInfo }

  it_behaves_like 'a realtime model', with_simple_attributes: %w(code status message) do
    let(:model_args) { [] }
  end
end
