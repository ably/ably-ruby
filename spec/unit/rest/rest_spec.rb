# encoding: utf-8
require 'spec_helper'

describe Ably::Rest do
  let(:options) { { key: 'app.key:secret' } }

  specify 'constructor returns an Ably::Rest::Client' do
    expect(Ably::Rest.new(options)).to be_instance_of(Ably::Rest::Client)
  end
end
