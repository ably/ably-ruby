module RSpec
  module ProtocolHelper
    SUPPORTED_PROTOCOLS = {
      json:    'JSON',
      msgpack: 'MsgPack'
    }

    PROTOCOLS = if ENV['PROTOCOL']
      protocol = ENV['PROTOCOL'].downcase.to_sym
      { protocol => SUPPORTED_PROTOCOLS[protocol] }
    else
      SUPPORTED_PROTOCOLS
    end

    def vary_by_protocol(&block)
      RSpec::ProtocolHelper::PROTOCOLS.each do |protocol, description|
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


