require 'spec_helper'

describe Ably::Modules::Enum, :api_private do
  class ExampleClassWithEnum
    extend Ably::Modules::Enum
    ENUMEXAMPLE = ruby_enum('ENUMEXAMPLE', :value_zero, 'value_1', :value_snake_case_2, :SentenceCase)
  end

  let(:enum) { ExampleClassWithEnum::ENUMEXAMPLE }
  let(:enum_name) { 'ENUMEXAMPLE' }

  context 'convertor method added to class' do
    subject { ExampleClassWithEnum }

    it 'converts symbols' do
      expect(subject.ENUMEXAMPLE(:value_zero)).to eql(enum.get(:value_zero))
    end

    it 'converts strings' do
      expect(subject.ENUMEXAMPLE('ValueZero')).to eql(enum.get(:value_zero))
    end

    it 'converts integer index' do
      expect(subject.ENUMEXAMPLE(0)).to eql(enum.get(:value_zero))
    end
  end

  context 'convertor method added to instance' do
    subject { ExampleClassWithEnum.new }

    it 'converts symbols' do
      expect(subject.ENUMEXAMPLE(:value_zero)).to eql(enum.get(:value_zero))
    end

    it 'converts strings' do
      expect(subject.ENUMEXAMPLE('ValueZero')).to eql(enum.get(:value_zero))
    end

    it 'converts integer index' do
      expect(subject.ENUMEXAMPLE(0)).to eql(enum.get(:value_zero))
    end
  end

  context 'defined Enum from Array class' do
    subject { enum }

    it 'provides a MixedCase const for each provided value' do
      expect(subject.ValueZero).to be_a(subject)
      expect(subject.ValueSnakeCase2).to be_a(subject)
    end

    context '#get' do
      context 'by integer index' do
        let(:return_val) { subject.get(0) }
        it 'returns an enum' do
          expect(return_val).to be_a(subject)
          expect(return_val.to_sym).to eql(:value_zero)
        end
      end

      context 'by string value' do
        let(:return_val) { subject.get('value_zero') }
        it 'returns an enum' do
          expect(return_val).to be_a(subject)
          expect(return_val.to_sym).to eql(:value_zero)
        end
      end

      context 'by symbol' do
        let(:return_val) { subject.get(:sentence_case) }
        it 'returns an enum' do
          expect(return_val).to be_a(subject)
          expect(return_val.to_sym).to eql(:sentence_case)
        end
      end

      context 'by enum' do
        let(:return_val) { subject.get(subject.get(:sentence_case)) }
        it 'returns an enum' do
          expect(return_val).to be_a(subject)
          expect(return_val.to_sym).to eql(:sentence_case)
        end
      end

      context 'by invalid type' do
        let(:return_val) { subject.get(Array.new) }
        it 'raises an error' do
          expect { return_val }.to raise_error KeyError
        end
      end
    end

    context '#[]' do
      let(:argument) { random_str }
      before do
        expect(subject).to receive(:get).with(argument).once.and_return(true)
      end

      it 'is an alias for get' do
        subject[argument]
      end
    end

    it 'returns the provided Enum name' do
      expect(subject.name).to eql(enum_name)
    end

    specify '#to_s returns the Enum name' do
      expect("#{subject}").to eql(enum_name)
    end

    context '#size' do
      it 'returns the number of enum items' do
        expect(subject.size).to eql(4)
      end

      it 'has alias #length' do
        expect(subject.length).to eql(subject.size)
      end
    end

    it 'freezes the Enum' do
      expect(subject.send(:by_index)).to be_frozen
    end

    it 'prevents modification' do
      expect { subject.send(:define_values, :enum_id) }.to raise_error RuntimeError, /cannot be modified/
    end

    it 'behaves like Enumerable' do
      expect(subject.map(&:to_sym)).to eql([:value_zero, :value_1, :value_snake_case_2, :sentence_case])
    end
  end

  context 'defined Enum from Hash class' do
    class ExampleClassWithEnumFromHash
      extend Ably::Modules::Enum
      ENUMEXAMPLE = ruby_enum('ENUMEXAMPLE',
        value_one:  1,
        value_five: 5
      )
    end

    subject { ExampleClassWithEnumFromHash::ENUMEXAMPLE }

    it 'provides a MixedCase const for each provided value' do
      expect(subject.ValueOne).to be_a(subject)
      expect(subject.ValueFive).to be_a(subject)
    end

    context '#get' do
      context 'by integer index for 1' do
        let(:return_val) { subject.get(1) }
        it 'returns an enum' do
          expect(return_val).to be_a(subject)
          expect(return_val.to_sym).to eql(:value_one)
        end
      end

      context 'by integer index for 5' do
        let(:return_val) { subject.get(5) }
        it 'returns an enum' do
          expect(return_val).to be_a(subject)
          expect(return_val.to_sym).to eql(:value_five)
        end
      end

      context 'by invalid integer index' do
        let(:return_val) { subject.get(0) }
        it 'raises an exception' do
          expect { return_val }.to raise_error KeyError
        end
      end

      context 'by string value' do
        let(:return_val) { subject.get('value_five') }
        it 'returns an enum' do
          expect(return_val).to be_a(subject)
          expect(return_val.to_sym).to eql(:value_five)
          expect(return_val.to_i).to eql(5)
        end
      end
    end
  end

  context 'defined Enum from another Enum' do
    class ExampleBaseEnum
      extend Ably::Modules::Enum
      ENUMEXAMPLE = ruby_enum('ENUMEXAMPLE', :one, :second_enum)
    end

    class ExampleOtherEnum
      extend Ably::Modules::Enum
      ENUMEXAMPLE = ruby_enum('ENUMEXAMPLE', ExampleBaseEnum::ENUMEXAMPLE)
    end

    subject { ExampleOtherEnum::ENUMEXAMPLE }

    it 'provides a MixedCase const for each provided value' do
      expect(subject.One).to be_a(subject)
      expect(subject.SecondEnum).to be_a(subject)
    end
  end

  context 'Enum instance' do
    context '#==' do
      subject { enum.get(:value_snake_case_2) }

      it 'compares with a symbol' do
        expect(subject).to eq(:value_Snake_Case_2)
      end

      it 'compares with a string' do
        expect(subject).to eq('ValueSnakeCase2')
      end

      it 'compares with a integer index' do
        expect(subject).to eq(subject.to_i)
      end

      it 'compares with itself' do
        expect(subject).to eq(subject)
      end

      it 'compares with other Objects' do
        expect(subject).to_not eq(Object.new)
      end
    end

    context '#to_s' do
      subject { enum.get(:value_zero) }

      it 'returns ENUMNAME.CamelCase name' do
        expect(subject.to_s).to eql("#{enum_name}.ValueZero")
      end
    end

    context '#to_sym' do
      subject { enum.get(:value_zero) }

      it 'returns a snake_case symbol' do
        expect(subject.to_sym).to eql(:value_zero)
      end
    end

    context '#to_i' do
      subject { enum.get(:value_1) }

      it 'returns the Enum index' do
        expect(subject.to_i).to eql(1)
      end
    end

    context '#to_json' do
      subject { enum.get(:value_1) }

      it 'returns a symbol string key value' do
        expect(subject.to_json).to eql('"value_1"')
      end
    end
  end
end
