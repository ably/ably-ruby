require 'spec_helper'

describe Ably::Realtime do
  let(:options) { { key: 'app.key:secret', auto_connect: false } }

  specify 'constructor returns an Ably::Realtime::Client' do
    expect(Ably::Realtime.new(options)).to be_instance_of(Ably::Realtime::Client)
  end

  after(:all) do
    sleep 1 # let realtime library shut down any open clients
  end
end
