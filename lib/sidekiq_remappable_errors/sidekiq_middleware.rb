# frozen_string_literal: true

module SidekiqRemappableErrors
  class SidekiqMiddleware
    def call(worker, job, _queue)
      worker.retry_count = job['retry_count'] if worker.respond_to?(:retry_count=)
      yield
    end
  end
end
