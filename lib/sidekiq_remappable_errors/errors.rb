# frozen_string_literal: true

module SidekiqRemappableErrors
  class InvalidConfigError < StandardError; end
  class InvalidErrorMatcherError < StandardError; end
  class RemappedError < StandardError; end
end
