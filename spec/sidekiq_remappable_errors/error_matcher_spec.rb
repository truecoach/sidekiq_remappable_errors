# frozen_string_literal: true

RSpec.describe SidekiqRemappableErrors::ErrorMatcher do
  describe '::new' do
    let(:instantiate) { -> { described_class.new(error_config) } }

    context 'given an array of error class + regex' do
      let(:error_config) { [ StandardError, /test/ ] }

      it 'initializes without error' do
        expect { instantiate.call }.not_to raise_error
      end
    end

    context 'given a array of non-error class + regex' do
      let(:error_config) { [ Object, /test/ ] }

      it 'initialization raises an error' do
        expect { instantiate.call }.to raise_error(
          SidekiqRemappableErrors::InvalidErrorMatcherError,
          /invalid/i
        )
      end
    end

    context 'given a non-array' do
      let(:error_config) { StandardError }

      it 'initialization raises an error' do
        expect { instantiate.call }.to raise_error(
          SidekiqRemappableErrors::InvalidErrorMatcherError,
          /invalid/i
        )
      end
    end
  end
end
