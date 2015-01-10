module RSpec
  module ProtocolHelper
    PROTOCOLS = {
      :json    => 'JSON',
      :msgpack => 'MsgPack'
    }

    def vary_by_protocol(&block)
      PROTOCOLS.each do |protocol, description|
        context("using #{description} protocol", protocol: protocol, &block)
      end
    end
  end
end

RSpec.configure do |config|
  config.extend RSpec::ProtocolHelper

  config.before(:context, protocol: :json) do |context|
    context.class.let(:protocol) { :json }
  end

  config.before(:context, protocol: :msgpack) do |context|
    context.class.let(:protocol) { :msgpack }
  end
end


