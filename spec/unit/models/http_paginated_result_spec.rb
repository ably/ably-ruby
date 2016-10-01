require 'spec_helper'
require 'ostruct'

describe "Ably::Models::HttpPaginatedResponse: #HP1 -> #HP8" do
  let(:paginated_result_class) { Ably::Models::HttpPaginatedResponse }
  let(:headers) { Hash.new }
  let(:client) do
    instance_double('Ably::Rest::Client', logger: Ably::Models::NilLogger.new).tap do |client|
      allow(client).to receive(:get).and_return(http_response)
    end
  end
  let(:body) do
    [
      { 'id' => 0 },
      { 'id' => 1 }
    ]
  end
  let(:status) { "200" }
  let(:http_response) do
    instance_double('Faraday::Response', {
      body: body,
      headers: headers,
      status: status
    })
  end
  let(:base_url) { 'http://rest.ably.io/channels/channel_name' }
  let(:full_url) { "#{base_url}/whatever?param=exists" }
  let(:paginated_result_options) { Hash.new }
  let(:first_paged_request) { paginated_result_class.new(http_response, full_url, client, paginated_result_options) }
  subject { first_paged_request }

  context '#items' do
    it 'returns correct length from body' do
      expect(subject.items.length).to eql(body.length)
    end

    it 'is Enumerable' do
      expect(subject.items).to be_kind_of(Enumerable)
    end

    it 'is iterable' do
      expect(subject.items.map { |d| d }).to eql(body)
    end

    context '#each' do
      it 'returns an enumerator' do
        expect(subject.items.each).to be_a(Enumerator)
      end

      it 'yields each item' do
        items = []
        subject.items.each do |item|
          items << item
        end
        expect(items).to eq(body)
      end
    end

    it 'provides [] accessor method' do
      expect(subject.items[0][:id]).to eql(body[0][:id])
      expect(subject.items[1][:id]).to eql(body[1][:id])
      expect(subject.items[2]).to be_nil
    end

    specify '#first gets the first item in page' do
      expect(subject.items.first[:id]).to eql(body[0][:id])
    end

    specify '#last gets the last item in page' do
      expect(subject.items.last[:id]).to eql(body[1][:id])
    end

    context 'with coercion', :api_private do
      let(:paginated_result_options) { { coerce_into: 'OpenStruct' } }

      it 'returns coerced objects' do
        expect(subject.items.first).to be_a(OpenStruct)
        expect(subject.items.first.id).to eql(body.first['id'])
      end
    end
  end

  context 'paged transformations', :api_private do
    let(:headers) do
      {
        'link' => [
          '<./history?index=1>; rel="next"'
        ].join(', ')
      }
    end
    let(:paged_client) do
      instance_double('Ably::Rest::Client', logger: Ably::Models::NilLogger.new).tap do |client|
        allow(client).to receive(:get).and_return(http_response_page2)
      end
    end
    let(:body_page2) do
      [
        { id: 2 },
        { id: 3 }
      ]
    end
    let(:http_response_page2) do
      instance_double('Faraday::Response', {
        body: body_page2,
        headers: headers
      })
    end

    context 'with each block' do
      subject do
        paginated_result_class.new(http_response, full_url, paged_client, paginated_result_options) do |result|
          result[:added_attribute_from_block] = "id:#{result[:id]}"
          result
        end
      end

      it 'calls the block for each result after retrieving the results' do
        expect(subject.items[0][:added_attribute_from_block]).to eql("id:#{body[0][:id]}")
      end

      it 'calls the block for each result on second page after retrieving the results' do
        page_1_first_id = subject.items[0][:id]
        next_page = subject.next

        expect(next_page.items[0][:added_attribute_from_block]).to eql("id:#{body_page2[0][:id]}")
        expect(next_page.items[0][:id]).to_not eql(page_1_first_id)
      end
    end

    if defined?(Ably::Realtime)
      context 'with option async_blocking_operations: true' do
        include RSpec::EventMachine

        subject do
          paginated_result_class.new(http_response, full_url, paged_client, async_blocking_operations: true)
        end

        context '#next' do
          it 'returns a SafeDeferrable that catches exceptions in callbacks and logs them' do
            run_reactor do
              expect(subject.next).to be_a(Ably::Util::SafeDeferrable)
              stop_reactor
            end
          end

          it 'allows a success callback block to be added' do
            run_reactor do
              subject.next do |paginated_result|
                expect(paginated_result).to be_a(Ably::Models::HttpPaginatedResponse)
                stop_reactor
              end
            end
          end
        end

        context '#first' do
          it 'calls the errback callback when first page headers are missing' do
            run_reactor do
              subject.next do |paginated_result|
                deferrable = subject.first
                deferrable.errback do |error|
                  expect(error).to be_a(Ably::Exceptions::PageMissing)
                  stop_reactor
                end
              end
            end
          end
        end
      end
    end
  end

  context 'with non paged http response' do
    it 'is the last page' do
      expect(subject).to be_last
    end

    it 'does not have next page' do
      expect(subject).to_not have_next
    end

    it 'does not support pagination' do
      expect(subject.supports_pagination?).to_not eql(true)
    end

    it 'returns nil when accessing next page' do
      expect(subject.next).to be_nil
    end

    it 'returns nil when accessing first page' do
      expect(subject.first).to be_nil
    end
  end

  context 'with paged http response' do
    let(:base_url) { 'http://rest.ably.io/channels/channel_name' }
    let(:full_url) { "#{base_url}/messages" }
    let(:headers) do
      {
        'link' => [
          '<./history?index=0>; rel="first"',
          '<./history?index=0>; rel="current"',
          '<./history?index=1>; rel="next"'
        ].join(', ')
      }
    end

    it 'has next page' do
      expect(subject).to have_next
    end

    it 'is not the last page' do
      expect(subject).to_not be_last
    end

    it 'supports pagination' do
      expect(subject.supports_pagination?).to eql(true)
    end

    context 'accessing next page' do
      let(:next_body) do
        [ { id: 2 } ]
      end
      let(:next_headers) do
        {
          'link' => [
            '<./history?index=0>; rel="first"',
            '<./history?index=1>; rel="current"'
          ].join(', ')
        }
      end
      let(:next_http_response) do
        double('http_response', {
          body: next_body,
          headers: next_headers
        })
      end
      let(:subject) { first_paged_request.next }

      before do
        expect(client).to receive(:get).with("#{base_url}/history?index=1").and_return(next_http_response).once
      end

      it 'returns another HttpPaginatedResponse' do
        expect(subject).to be_a(paginated_result_class)
      end

      it 'retrieves the next page of results' do
        expect(subject.items.length).to eql(next_body.length)
        expect(subject.items[0][:id]).to eql(next_body[0][:id])
      end

      it 'does not have a next page' do
        expect(subject).to_not have_next
      end

      it 'is the last page' do
        expect(subject).to be_last
      end

      it 'returns nil when trying to access the last page when it is the last page' do
        expect(subject).to be_last
        expect(subject.next).to be_nil
      end

      context 'and then first page' do
        before do
          expect(client).to receive(:get).with("#{base_url}/history?index=0").and_return(http_response).once
        end
        subject { first_paged_request.next.first }

        it 'returns a HttpPaginatedResponse' do
          expect(subject).to be_a(paginated_result_class)
        end

        it 'retrieves the first page of results' do
          expect(subject.items.length).to eql(body.length)
        end
      end
    end
  end

  context 'response metadata' do
    context 'successful response' do
      let(:headers) { { 'Content-type' => 'application/json' } }
      let(:status) { 200 }

      specify '#success? is true' do
        expect(subject).to be_succes
      end

      specify '#status_code reflects status code' do
        expect(subject.status_code).to eql(200)
      end

      specify '#error_code to be empty' do
        expect(subject.error_code).to be_nil
      end

      specify '#error_message to be empty' do
        expect(subject.error_message).to be_nil
      end

      specify '#headers to be a hash' do
        expect(subject.headers['Content-type']).to eql('application/json')
      end
    end

    context 'failed response' do
      let(:headers) { { 'X-Ably-Errormessage' => 'Fault', 'X-Ably-Errorcode' => '500' } }
      let(:status) { 500 }

      specify '#success? is false' do
        expect(subject).to_not be_succes
      end

      specify '#status_code reflects status code' do
        expect(subject.status_code).to eql(500)
      end

      specify '#error_code to be populated' do
        expect(subject.error_code).to eql(500)
      end

      specify '#error_message to be populated' do
        expect(subject.error_message).to eql('Fault')
      end

      specify '#headers to be present' do
        expect(subject.headers['X-Ably-Errormessage']).to eql('Fault')
      end
    end
  end

  context '#items Array conversion and nil handling #HP3' do
    context 'with Json Array' do
      let(:body) do
        [
          { 'id' => 0 },
          { 'id' => 1 }
        ]
      end

      it 'is an array' do
        expect(subject.items.length).to eql(2)
      end
    end

    context 'with Json Object' do
      let(:body) do
        { 'id' => 0 }
      end

      it 'is an array' do
        expect(subject.items.length).to eql(1)
        expect(subject.items.first['id']).to eql(0)
      end
    end

    context 'with empty response' do
      let(:body) do
        ''
      end

      it 'is an array' do
        expect(subject.items.length).to eql(0)
      end
    end

    context 'with nil response' do
      let(:body) do
        nil
      end

      it 'is an array' do
        expect(subject.items.length).to eql(0)
      end
    end
  end
end
