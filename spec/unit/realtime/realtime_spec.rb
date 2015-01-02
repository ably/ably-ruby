require 'spec_helper'

describe Ably::Realtime do
  let(:options) { { api_key: 'app.key:secret' } }

  specify 'constructor returns an Ably::Realtime::Client' do
    expect(Ably::Realtime.new(options)).to be_instance_of(Ably::Realtime::Client)
  end
end
