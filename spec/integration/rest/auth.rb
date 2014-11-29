require 'spec_helper'

describe Ably::Auth do
  let(:client) { Ably::Rest::Client.new(key_id: 'id', key_secret: 'secret') }

  it 'has immutable options' do
    expect { client.auth.options['key_id'] = 'new_id' }.to raise_error RuntimeError, /can't modify frozen Hash/
  end
end
