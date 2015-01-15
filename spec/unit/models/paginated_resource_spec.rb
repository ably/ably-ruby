require 'spec_helper'
require 'ostruct'

describe Ably::Models::PaginatedResource do
  let(:paginated_resource_class) { Ably::Models::PaginatedResource }
  let(:headers) { Hash.new }
  let(:client) do
    instance_double('Ably::Rest::Client').tap do |client|
      allow(client).to receive(:get).and_return(http_response)
    end
  end
  let(:body) do
    [
      { id: 0 },
      { id: 1 }
    ]
  end
  let(:http_response) do
    instance_double('Faraday::Response', {
      body: body,
      headers: headers
    })
  end
  let(:base_url) { 'http://rest.ably.io/channels/channel_name' }
  let(:full_url) { "#{base_url}/whatever?param=exists" }
  let(:paginated_resource_options) { Hash.new }
  let(:first_paged_request) { paginated_resource_class.new(http_response, full_url, client, paginated_resource_options) }
  subject { first_paged_request }

  it 'returns correct length from body' do
    expect(subject.length).to eql(body.length)
  end

  it 'supports alias methods for length' do
    expect(subject.count).to eql(subject.length)
    expect(subject.size).to eql(subject.length)
  end

  it 'is Enumerable' do
    expect(subject).to be_kind_of(Enumerable)
  end

  it 'is iterable' do
    expect(subject.map { |d| d }).to eql(body)
  end

  context '#each' do
    it 'returns an enumerator' do
      expect(subject.each).to be_a(Enumerator)
    end

    it 'yields each item' do
      items = []
      subject.each do |item|
        items << item
      end
      expect(items).to eq(body)
    end
  end

  it 'provides [] accessor method' do
    expect(subject[0][:id]).to eql(body[0][:id])
    expect(subject[1][:id]).to eql(body[1][:id])
    expect(subject[2]).to be_nil
  end

  specify '#first gets the first item in page' do
    expect(subject.first[:id]).to eql(body[0][:id])
  end

  specify '#last gets the last item in page' do
    expect(subject.last[:id]).to eql(body[1][:id])
  end

  context 'with coercion', :api_private do
    let(:paginated_resource_options) { { coerce_into: 'OpenStruct' } }

    it 'returns coerced objects' do
      expect(subject.first).to be_a(OpenStruct)
      expect(subject.first.id).to eql(body.first[:id])
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
      instance_double('Ably::Rest::Client').tap do |client|
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
        paginated_resource_class.new(http_response, full_url, paged_client, paginated_resource_options) do |resource|
          resource[:added_attribute_from_block] = "id:#{resource[:id]}"
          resource
        end
      end

      it 'calls the block for each resource after retrieving the resources' do
        expect(subject[0][:added_attribute_from_block]).to eql("id:#{body[0][:id]}")
      end

      it 'calls the block for each resource on second page after retrieving the resources' do
        page_1_first_id = subject[0][:id]
        next_page = subject.next_page

        expect(next_page[0][:added_attribute_from_block]).to eql("id:#{body_page2[0][:id]}")
        expect(next_page[0][:id]).to_not eql(page_1_first_id)
      end
    end

    if defined?(EventMachine)
      context 'with option async_blocking_operations: true' do
        include RSpec::EventMachine

        subject do
          paginated_resource_class.new(http_response, full_url, paged_client, async_blocking_operations: true)
        end

        context '#next_page' do
          it 'returns a deferrable object' do
            run_reactor do
              expect(subject.next_page).to be_a(EventMachine::Deferrable)
              stop_reactor
            end
          end

          it 'allows a success callback block to be added' do
            run_reactor do
              subject.next_page do |paginated_resource|
                expect(paginated_resource).to be_a(Ably::Models::PaginatedResource)
                stop_reactor
              end
            end
          end
        end

        context '#first_page' do
          it 'calls the errback callback when first page headers are missing' do
            run_reactor do
              subject.next_page do |paginated_resource|
                deferrable = subject.first_page
                deferrable.errback do |error|
                  expect(error).to be_a(Ably::Exceptions::InvalidPageError)
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
    it 'is the first page' do
      expect(subject).to be_first_page
    end

    it 'is the last page' do
      expect(subject).to be_last_page
    end

    it 'does not support pagination' do
      expect(subject.supports_pagination?).to_not eql(true)
    end

    it 'raises an exception when accessing next page' do
      expect { subject.next_page }.to raise_error Ably::Exceptions::InvalidPageError, /Paging header link next/
    end

    it 'raises an exception when accessing first page' do
      expect { subject.first_page }.to raise_error Ably::Exceptions::InvalidPageError, /Paging header link first/
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

    it 'is the first page' do
      expect(subject).to be_first_page
    end

    it 'is not the last page' do
      expect(subject).to_not be_last_page
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
      let(:subject) { first_paged_request.next_page }

      before do
        expect(client).to receive(:get).with("#{base_url}/history?index=1").and_return(next_http_response).once
      end

      it 'returns another PaginatedResource' do
        expect(subject).to be_a(paginated_resource_class)
      end

      it 'retrieves the next page of results' do
        expect(subject.length).to eql(next_body.length)
        expect(subject[0][:id]).to eql(next_body[0][:id])
      end

      it 'is not the first page' do
        expect(subject).to_not be_first_page
      end

      it 'is the last page' do
        expect(subject).to be_last_page
      end

      it 'raises an exception if trying to access the last page when it is the last page' do
        expect(subject).to be_last_page
        expect { subject.next_page }.to raise_error Ably::Exceptions::InvalidPageError, /There are no more pages/
      end

      context 'and then first page' do
        before do
          expect(client).to receive(:get).with("#{base_url}/history?index=0").and_return(http_response).once
        end
        subject { first_paged_request.next_page.first_page }

        it 'returns a PaginatedResource' do
          expect(subject).to be_a(paginated_resource_class)
        end

        it 'retrieves the first page of results' do
          expect(subject.length).to eql(body.length)
        end

        it 'is the first page' do
          expect(subject).to be_first_page
        end
      end
    end
  end
end

