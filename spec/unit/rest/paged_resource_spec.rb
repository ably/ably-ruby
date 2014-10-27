require 'spec_helper'
require 'ostruct'

describe Ably::Rest::Models::PagedResource do
  let(:paged_resource_class) { Ably::Rest::Models::PagedResource }
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
  let(:paged_resource_options) { Hash.new }
  let(:first_paged_request) { paged_resource_class.new(http_response, full_url, client, paged_resource_options) }
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

  it 'provides [] accessor method' do
    expect(subject[0][:id]).to eql(body[0][:id])
    expect(subject[1][:id]).to eql(body[1][:id])
    expect(subject[2]).to be_nil
  end

  context 'with coercion' do
    let(:paged_resource_options) { { coerce_into: 'OpenStruct' } }

    it 'returns coerced objects' do
      expect(subject.first).to be_a(OpenStruct)
      expect(subject.first.id).to eql(body.first[:id])
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

      it 'returns another PagedResource' do
        expect(subject).to be_a(paged_resource_class)
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

        it 'returns a PagedResource' do
          expect(subject).to be_a(paged_resource_class)
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

