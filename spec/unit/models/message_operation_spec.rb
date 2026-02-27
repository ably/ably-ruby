# encoding: utf-8
require 'spec_helper'

describe Ably::Models::MessageOperation do
  subject { Ably::Models::MessageOperation }

  context '#client_id (#MOP2a)' do
    let(:model) { subject.new(client_id: 'user123') }

    it 'returns the client_id' do
      expect(model.client_id).to eql('user123')
    end
  end

  context '#description (#MOP2b)' do
    let(:model) { subject.new(description: 'Edited for clarity') }

    it 'returns the description' do
      expect(model.description).to eql('Edited for clarity')
    end
  end

  context '#metadata (#MOP2c)' do
    let(:model) { subject.new(metadata: { 'reason' => 'typo' }) }

    it 'returns the metadata hash' do
      expect(model.metadata).to eq({ 'reason' => 'typo' })
    end
  end

  context 'when empty' do
    let(:model) { subject.new({}) }

    it 'returns nil for all fields' do
      expect(model.client_id).to be_nil
      expect(model.description).to be_nil
      expect(model.metadata).to be_nil
    end
  end

  context 'with camelCase keys from wire' do
    let(:model) { subject.new('clientId' => 'user456') }

    it 'converts to snake_case access' do
      expect(model.client_id).to eql('user456')
    end
  end

  context '#attributes' do
    let(:model) { subject.new(description: 'test') }

    it 'prevents modification' do
      expect { model.attributes[:description] = 'changed' }.to raise_error(/can't modify frozen|FrozenError/)
    end
  end

  context '#as_json' do
    let(:model) { subject.new(client_id: 'user', description: 'edit') }

    it 'returns a hash suitable for JSON serialization' do
      json = model.as_json
      expect(json).to be_a(Hash)
      expect(json['clientId']).to eql('user')
      expect(json['description']).to eql('edit')
    end
  end
end
