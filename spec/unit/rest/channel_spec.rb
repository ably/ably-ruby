# frozen_string_literal: true

require "spec_helper"

describe Ably::Rest::Channel do
  let(:client) do
    instance_double(
      "Ably::Rest::Client",
      encoders: [],
      post: instance_double("Faraday::Response", status: 201),
      idempotent_rest_publishing: false, max_message_size: max_message_size
    )
  end
  let(:channel_name) { "unique" }
  let(:max_message_size) { nil }

  subject { Ably::Rest::Channel.new(client, channel_name) }

  describe "#initializer" do
    let(:channel_name) { random_str.encode(encoding) }

    context "as UTF_8 string" do
      let(:encoding) { Encoding::UTF_8 }

      it "is permitted" do
        expect(subject.name).to eql(channel_name)
      end

      it "remains as UTF-8" do
        expect(subject.name.encoding).to eql(encoding)
      end
    end

    context "as frozen UTF_8 string" do
      let(:channel_name) { "unique" }
      let(:encoding) { Encoding::UTF_8 }

      it "is permitted" do
        expect(subject.name).to eql(channel_name)
      end

      it "remains as UTF-8" do
        expect(subject.name.encoding).to eql(encoding)
      end
    end

    context "as SHIFT_JIS string" do
      let(:encoding) { Encoding::SHIFT_JIS }

      it "gets converted to UTF-8" do
        expect(subject.name.encoding).to eql(Encoding::UTF_8)
      end

      it "is compatible with original encoding" do
        expect(subject.name.encode(encoding)).to eql(channel_name)
      end
    end

    context "as ASCII_8BIT string" do
      let(:encoding) { Encoding::ASCII_8BIT }

      it "gets converted to UTF-8" do
        expect(subject.name.encoding).to eql(Encoding::UTF_8)
      end

      it "is compatible with original encoding" do
        expect(subject.name.encode(encoding)).to eql(channel_name)
      end
    end

    context "as Integer" do
      let(:channel_name) { 1 }

      it "raises an argument error" do
        expect { subject }.to raise_error ArgumentError, /must be a String/
      end
    end

    context "as Nil" do
      let(:channel_name) { nil }

      it "raises an argument error" do
        expect { subject }.to raise_error ArgumentError, /must be a String/
      end
    end
  end

  describe "#publish name argument" do
    let(:encoded_value) { random_str.encode(encoding) }

    context "as UTF_8 string" do
      let(:encoding) { Encoding::UTF_8 }

      it "is permitted" do
        expect(subject.publish(encoded_value, "data")).to eql(true)
      end
    end

    context "as frozen UTF_8 string" do
      let(:encoded_value) { "unique" }
      let(:encoding) { Encoding::UTF_8 }

      it "is permitted" do
        expect(subject.publish(encoded_value, "data")).to eql(true)
      end
    end

    context "as SHIFT_JIS string" do
      let(:encoding) { Encoding::SHIFT_JIS }

      it "is permitted" do
        expect(subject.publish(encoded_value, "data")).to eql(true)
      end
    end

    context "as ASCII_8BIT string" do
      let(:encoding) { Encoding::ASCII_8BIT }

      it "is permitted" do
        expect(subject.publish(encoded_value, "data")).to eql(true)
      end
    end

    context "as Integer" do
      let(:encoded_value) { 1 }

      it "raises an argument error" do
        expect { subject.publish(encoded_value, "data") }.to raise_error ArgumentError, /must be a String/
      end
    end

    context "max message size exceeded" do
      context "when max_message_size is nil" do
        context "and a message size is 65537 bytes" do
          it "should raise Ably::Exceptions::MaxMessageSizeExceeded" do
            expect { subject.publish("x" * 65_537, "data") }.to raise_error Ably::Exceptions::MaxMessageSizeExceeded
          end
        end
      end

      context "when max_message_size is 65536 bytes" do
        let(:max_message_size) { 65_536 }

        context "and a message size is 65537 bytes" do
          it "should raise Ably::Exceptions::MaxMessageSizeExceeded" do
            expect { subject.publish("x" * 65_537, "data") }.to raise_error Ably::Exceptions::MaxMessageSizeExceeded
          end
        end

        context "and a message size is 10 bytes" do
          it "should send a message" do
            expect(subject.publish("x" * 10, "data")).to eq(true)
          end
        end
      end

      context "when max_message_size is 10 bytes" do
        let(:max_message_size) { 10 }

        context "and a message size is 11 bytes" do
          it "should raise Ably::Exceptions::MaxMessageSizeExceeded" do
            expect { subject.publish("x" * 11, "data") }.to raise_error Ably::Exceptions::MaxMessageSizeExceeded
          end
        end

        context "and a message size is 2 bytes" do
          it "should send a message" do
            expect(subject.publish("x" * 2, "data")).to eq(true)
          end
        end
      end
    end
  end
end
