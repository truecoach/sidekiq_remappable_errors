# frozen_string_literal: true

RSpec.describe SidekiqRemappableErrors::Config do
  let(:config) do
    described_class.new(
      remapped_error_class: remapped_error_class
    )
  end

  describe '#validate!' do
    context 'given a valid error class' do
      let(:remapped_error_class) { StandardError }

      it 'returns true' do
        expect(config.validate!).to eq(true)
      end
    end

    context 'given an invalid error class' do
      let(:remapped_error_class) { Object }

      it 'raises an error' do
        expect { config.validate! }.to raise_error(
          SidekiqRemappableErrors::InvalidConfigError, /must be an exception/i
        )
      end
    end
  end
end
