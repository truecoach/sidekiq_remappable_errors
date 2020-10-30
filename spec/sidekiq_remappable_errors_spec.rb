# frozen_string_literal: true

RSpec.describe SidekiqRemappableErrors do
  after(:each) do
    Object.send(:remove_const, :TestJobError) if Object.const_defined?(:TestJobError)
    Object.send(:remove_const, :TestJobBase) if Object.const_defined?(:TestJobBase)
    Object.send(:remove_const, :TestJob)
  end

  let(:mock_described_class) { TestJob }
  let(:job) { mock_described_class.new }

  it 'does not allow an invalid remapping config' do
    expect do
      class TestJob
        include Sidekiq::Worker
        include SidekiqRemappableErrors

        remappable_errors [
          StandardError, /test/
        ]
      end
    end.to raise_error(/invalid remappable error definition/i)
  end

  context 'given a job defined with silent retries' do
    let(:error_message) { 'test-message' }
    let(:error_class) { StandardError }

    before(:each) do
      class TestJobError < StandardError; end
      class TestJob
        include Sidekiq::Worker
        include SidekiqRemappableErrors

        sidekiq_options retry: 1

        remappable_errors [
          [StandardError, /test/]
        ]

        def perform(error_class, error_message)
          with_remappable_errors do
            raise error_class, error_message
          end
        end
      end
    end

    def perform!
      job.perform(error_class, error_message)
    end

    context 'given a retry count that should remap the error' do
      before(:each) do
        job.public_send(:retry_count=, 0)
      end

      it 'raises the remapped error' do
        expect { perform! }.to raise_error(SidekiqRemappableErrors::RemappedError, '#<StandardError: test-message>')
      end

      context 'if the error message does not match' do
        let(:error_message) { 'unmatched' }

        it 'raises the original error' do
          expect { perform! }.to raise_error(error_class, error_message)
        end
      end

      context 'if the error class does not match' do
        let(:error_class) { TestJobError }

        it 'raises the original error' do
          expect { perform! }.to raise_error(error_class, error_message)
        end
      end
    end

    context 'given a retry count that should not be remapped' do
      before(:each) do
        job.public_send(:retry_count=, 1)
      end

      it 'raises the original error' do
        expect { perform! }.to raise_error(error_class, error_message)
      end
    end
  end

  context 'given a job defined with a large number of retries' do
    before(:each) do
      class TestJob
        include Sidekiq::Worker
        include SidekiqRemappableErrors

        sidekiq_options retry: 25

        remappable_errors [
          [StandardError, //]
        ]

        def perform(_str)
          with_remappable_errors do
            raise StandardError, 'test-message'
          end
        end
      end

      job.public_send(:retry_count=, TestJob.remappable_errors_options_store[:max_remaps])
    end

    def perform!
      job.perform('test')
    end

    it 'raises the original error after the max # of remappable retries is reached' do
      expect { perform! }.to raise_error(StandardError, 'test-message')
    end
  end

  context 'given a subclassed job' do
    before(:each) do
      class TestJobError < StandardError; end
      class TestJobBase
        include Sidekiq::Worker
        include SidekiqRemappableErrors

        remappable_errors_options max_remaps: 1

        remappable_errors [
          [NoMethodError, //]
        ]
      end

      class TestJob < TestJobBase
        remappable_errors [
          [ZeroDivisionError, //]
        ]
      end
    end

    it 'inherits the remappable errors' do
      remapped_errors = TestJob.error_matchers_store.map(&:klass)

      expect(remapped_errors).to contain_exactly(NoMethodError, ZeroDivisionError)
    end

    it 'does not modify the base jobs remappable errors' do
      remapped_errors = TestJobBase.error_matchers_store.map(&:klass)

      expect(remapped_errors).to contain_exactly(NoMethodError)
    end
  end
end
