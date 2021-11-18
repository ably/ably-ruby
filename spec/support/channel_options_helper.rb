module RSpec
  module ChannelOptionsHelper
    def with_different_option_types(var_name, &block)
      shared_examples 'a method that accepts different types of channel options' do
        describe 'hash' do
          let(:channel_options) { public_send(var_name) }
          it { expect(channel_options).to be_a(Hash) }
          context("when options are Hash", &block)
        end

        describe 'object' do
          let(:channel_options) { Ably::Models::ChannelOptions.new(public_send(var_name)) }
          it { expect(channel_options).to be_a(Ably::Models::ChannelOptions) }
          context("when options are ChannelOptions", &block)
        end
      end

      it_behaves_like 'a method that accepts different types of channel options'
    end
  end
end

RSpec.configure do |config|
  config.extend RSpec::ChannelOptionsHelper
end
