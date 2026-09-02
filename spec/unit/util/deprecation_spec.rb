# encoding: utf-8
require 'spec_helper'

# :deprecation opts out of the suite-wide suppression in spec/rspec_config.rb
describe Ably::Util::Deprecation, :deprecation do
  let(:rest_options)     { { key: 'appid.keyuid:keysecret' } }
  let(:realtime_options) { { key: 'appid.keyuid:keysecret', auto_connect: false } }

  before do
    # A warning is emitted once per call site, so a retried example would see none
    Ably::Util::Deprecation.reset_warnings!
  end

  context 'Ably::Rest::Client.new' do
    it 'names the server gem factory' do
      expect(Kernel).to receive(:warn).with(
        /Ably::Rest::Client\.new is deprecated.+Ably::PubSub::Server\.create_http_client, from the ably-pubsub-server gem/
      )
      Ably::Rest::Client.new(rest_options)
    end

    it 'says that the constructor keeps working' do
      expect(Kernel).to receive(:warn).with(/keeps working and is not scheduled for removal/)
      Ably::Rest::Client.new(rest_options)
    end

    it 'attributes the warning to the calling code' do
      expect(Kernel).to receive(:warn).with(a_string_starting_with("#{__FILE__}:"))
      Ably::Rest::Client.new(rest_options)
    end

    it 'warns once for a call site reached more than once' do
      expect(Kernel).to receive(:warn).once
      2.times { Ably::Rest::Client.new(rest_options) }
    end

    it 'warns for each distinct call site' do
      expect(Kernel).to receive(:warn).twice
      Ably::Rest::Client.new(rest_options)
      Ably::Rest::Client.new(rest_options)
    end
  end

  context 'Ably::Realtime::Client.new' do
    it 'names both factories, either of which returns this client' do
      expect(Kernel).to receive(:warn).with(
        /Ably::Realtime::Client\.new is deprecated.+Ably::PubSub::Server\.create_realtime_client.+Ably::PubSub::Device\.create_client/
      )
      Ably::Realtime::Client.new(realtime_options)
    end

    # The realtime client builds a REST client, which must not warn about itself as well
    it 'warns once' do
      expect(Kernel).to receive(:warn).once
      Ably::Realtime::Client.new(realtime_options)
    end
  end

  context 'the convenience constructors' do
    it 'attributes Ably::Rest.new to the calling code, not to itself' do
      expect(Kernel).to receive(:warn).with(a_string_starting_with("#{__FILE__}:"))
      Ably::Rest.new(rest_options)
    end

    it 'attributes Ably::Realtime.new to the calling code, not to itself' do
      expect(Kernel).to receive(:warn).with(a_string_starting_with("#{__FILE__}:"))
      Ably::Realtime.new(realtime_options)
    end
  end

  context '#suppress_constructor_deprecation' do
    it 'silences the warning within the block' do
      expect(Kernel).to_not receive(:warn)
      Ably::Util::Deprecation.suppress_constructor_deprecation { Ably::Rest::Client.new(rest_options) }
    end

    it 'restores the warning after the block' do
      Ably::Util::Deprecation.suppress_constructor_deprecation { Ably::Rest::Client.new(rest_options) }
      expect(Kernel).to receive(:warn).once
      Ably::Rest::Client.new(rest_options)
    end

    it 'restores the warning after the block raises' do
      expect do
        Ably::Util::Deprecation.suppress_constructor_deprecation { raise 'boom' }
      end.to raise_error('boom')
      expect(Kernel).to receive(:warn).once
      Ably::Rest::Client.new(rest_options)
    end

    it 'leaves an enclosing suppression in place' do
      expect(Kernel).to_not receive(:warn)
      Ably::Util::Deprecation.suppress_constructor_deprecation do
        Ably::Util::Deprecation.suppress_constructor_deprecation { }
        Ably::Rest::Client.new(rest_options)
      end
    end

    it 'returns the value of the block' do
      expect(Ably::Util::Deprecation.suppress_constructor_deprecation { :result }).to eql(:result)
    end
  end
end
