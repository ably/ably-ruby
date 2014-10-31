require 'spec_helper'
require 'securerandom'

describe Ably::Models::IdiomaticRubyWrapper do
  include Ably::Modules::Conversions

  let(:mixed_case_data) do
    {
      'mixedCase' => 'true',
      'simple' => 'without case',
      'hashObject' => {
        'mixedCaseChild' => 'exists'
      },
      'arrayObject' => [
        {
          'mixedCaseChild' => 'exists'
        }
      ],
    }
  end
  subject { Ably::Models::IdiomaticRubyWrapper.new(mixed_case_data) }

  context 'Kernel.Array like method to create a IdiomaticRubyWrapper' do
    it 'will return the same IdiomaticRubyWrapper if passed in' do
      expect(IdiomaticRubyWrapper(subject)).to eql(subject)
    end

    it 'will return the same IdiomaticRubyWrapper if passed in' do
      expect(IdiomaticRubyWrapper(mixed_case_data)).to be_a(Ably::Models::IdiomaticRubyWrapper)
    end
  end

  it 'provides accessor method to values using snake_case' do
    expect(subject[:mixed_case]).to eql('true')
    expect(subject[:simple]).to eql('without case')
  end

  it 'provides methods to read values using snake_case' do
    expect(subject.mixed_case).to eql('true')
    expect(subject.simple).to eql('without case')
  end

  it 'provides accessor set method to values using snake_case' do
    subject[:mixed_case] = 'mixedCase'
    subject[:simple] = 'simple'
    expect(subject[:mixed_case]).to eql('mixedCase')
    expect(subject[:simple]).to eql('simple')
  end

  it 'provides methods to write values using snake_case' do
    subject.mixed_case = 'mixedCase'
    subject.simple = 'simple'
    expect(subject.mixed_case).to eql('mixedCase')
    expect(subject.simple).to eql('simple')
  end

  it 'does not provide methods for keys that are missing' do
    expect { subject.no_key_exists_for_this }.to raise_error NoMethodError
  end

  specify '#hash returns raw Hash object' do
    expect(subject.hash).to eql(mixed_case_data)
  end

  context 'recursively wrapping child objects' do
    it 'wraps Hashes' do
      expect(subject.hash_object.mixed_case_child).to eql('exists')
    end

    it 'ignores arrays' do
      expect(subject.array_object.first).to include('mixedCaseChild' => 'exists')
    end

    context ':stop_at option' do
      subject { Ably::Models::IdiomaticRubyWrapper.new(mixed_case_data, stop_at: stop_at) }

      context 'with symbol' do
        let(:stop_at) { :hash_object }

        it 'does not wrap the matching key' do
          expect(subject.hash_object).to include('mixedCaseChild' => 'exists')
        end
      end

      context 'with string' do
        let(:stop_at) { ['hashObject'] }

        it 'does not wrap the matching key' do
          expect(subject.hash_object).to include('mixedCaseChild' => 'exists')
        end
      end
    end
  end

  context 'non standard mixedCaseData' do
    let(:data) do
      {
        :symbol             => 'aSymbolValue',
        :snake_case_symbol  => 'snake_case_symbolValue',
        :mixedCaseSymbol    => 'mixedCaseSymbolValue',
        'snake_case_string' => 'snake_case_stringValue',
        'mixedCaseString'   => 'mixedCaseStringFirstChoiceValue',
        :mixedCaseString    => 'mixedCaseStringFallbackValue',
        :CamelCaseSymbol    => 'CamelCaseSymbolValue',
        'CamelCaseString'   => 'camel_case_stringValue',
        :lowercasesymbol    => 'lowercasesymbolValue',
        'lowercasestring'   => 'lowercasestringValue'
      }
    end
    let(:unique_value) { SecureRandom.hex }

    subject { Ably::Models::IdiomaticRubyWrapper.new(data) }

    {
      :symbol => 'aSymbolValue',
      :snake_case_symbol    => 'snake_case_symbolValue',
      :mixed_case_symbol    => 'mixedCaseSymbolValue',
      :snake_case_string    => 'snake_case_stringValue',
      :mixed_case_string    => 'mixedCaseStringFirstChoiceValue',
      :camel_case_symbol    => 'CamelCaseSymbolValue',
      :camel_case_string    => 'camel_case_stringValue',
      :lower_case_symbol      => 'lowercasesymbolValue',
      :lower_case_string      => 'lowercasestringValue'
    }.each do |symbol_accessor, expected_value|
      context symbol_accessor do
        it 'allows access to non conformant keys but prefers correct mixedCaseSyntax' do
          expect(subject[symbol_accessor]).to eql(expected_value)
        end

        context 'updates' do
          before do
            subject[symbol_accessor] = unique_value
          end

          it 'returns the new value' do
            expect(subject[symbol_accessor]).to eql(unique_value)
          end

          it 'returns the new value in the JSON' do
            expect(subject.to_json).to include(unique_value)
            expect(subject.to_json).to_not include(expected_value)
          end
        end
      end
    end

    it 'returns nil for non existent keys' do
      expect(subject[:non_existent_key]).to eql(nil)
    end

    context 'new keys' do
      before do
        subject[:new_key] = 'new_value'
      end

      it 'uses mixedCase' do
        expect(subject.hash['newKey']).to eql('new_value')
        expect(subject.new_key).to eql('new_value')
      end
    end
  end

  context 'acts like a duck' do
    specify '#to_json returns JSON stringified' do
      expect(subject.to_json).to eql(mixed_case_data.to_json)
    end

    context '#to_json with changes' do
      before do
        @original_mixed_case_data = mixed_case_data.to_json
        subject[:mixed_case] = 'new_value'
      end

      it 'returns stringified JSON with changes' do
        expect(subject.to_json).to_not eql(@original_mixed_case_data)
        expect(subject.to_json).to match('new_value')
      end
    end

    it 'returns correct size' do
      expect(subject.size).to eql(mixed_case_data.size)
    end

    it 'supports Hash-like #keys' do
      expect(subject.keys.length).to eql(mixed_case_data.keys.length)
    end

    it 'supports Hash-like #values' do
      expect(subject.values.length).to eql(mixed_case_data.values.length)
    end

    it 'is Enumerable' do
      expect(subject).to be_kind_of(Enumerable)
    end

    context 'iterable' do
      subject { Ably::Models::IdiomaticRubyWrapper.new(mixed_case_data, stop_at: [:hash_object, :array_object]) }

      it 'yields key value pairs' do
        expect(subject.map { |k,v| k }).to eql([:mixed_case, :simple, :hash_object, :array_object])
        expect(subject.map { |k,v| v }).to eql(mixed_case_data.map { |k,v| v })
      end
    end

    context '#fetch' do
      it 'fetches the key' do
        expect(subject.fetch(:mixed_case)).to eql('true')
      end

      it 'raise an exception if key does not exist' do
        expect { subject.fetch(:non_existent) }.to raise_error KeyError, /key not found: non_existent/
      end

      it 'allows a default value argument' do
        expect(subject.fetch(:non_existent, 'default')).to eql('default')
      end

      it 'calls the block if key does not exist' do
        expect(subject.fetch(:non_existent) { 'block_default' } ).to eql('block_default')
      end
    end

    context '#==' do
      let(:mixed_case_data) do
        {
          'key' => 'value'
        }
      end
      let(:presented_as_data) do
        {
          :key => 'value'
        }
      end
      let(:invalid_match) do
        {
          :key => 'other value'
        }
      end
      let(:other) { Ably::Models::IdiomaticRubyWrapper.new(mixed_case_data) }
      let(:other_invalid) { Ably::Models::IdiomaticRubyWrapper.new(invalid_match) }

      it 'presents itself as a symbolized version of the object' do
        expect(subject).to eq(presented_as_data)
      end

      it 'returns false if different values to another Hash' do
        expect(subject).to_not eq(invalid_match)
      end

      it 'compares with itself' do
        expect(subject).to eq(other)
      end

      it 'returns false if different values to another IdiomaticRubyWrapper' do
        expect(subject).to_not eq(other_invalid)
      end

      it 'returns false if comparing with a non Hash/IdiomaticRubyWrapper object' do
        expect(subject).to_not eq(Object)
      end
    end

    context '#to_hash' do
      let(:mixed_case_data) do
        {
          'key' => 'value'
        }
      end

      it 'returns a hash' do
        expect(subject.to_hash).to include(key: 'value')
      end
    end

    context '#dup' do
      let(:mixed_case_data) do
        {
          'key' => 'value'
        }.freeze
      end
      let(:dupe) { subject.dup }

      it 'returns a new object with the underlying JSON duped' do
        expect(subject.hash).to be_frozen
        expect(dupe.hash).to_not be_frozen
      end

      it 'returns a new IdiomaticRubyWrapper with the same underlying Hash object' do
        expect(dupe).to be_a(Ably::Models::IdiomaticRubyWrapper)
        expect(dupe.hash).to be_a(Hash)
        expect(dupe.hash).to eql(mixed_case_data)
      end
    end
  end
end
