# frozen_string_literal: true

module SidekiqRemappableErrors
  class ErrorMatcher
    def initialize(config)
      validate_config!(config)

      @klass = config[0]
      @regex = config[1]
    end

    attr_reader :klass, :regex

    def match?(error)
      @klass.to_s == error.class.to_s && error.message.match(@regex)
    end

    private

    def validate_config!(config)
      return if valid_config?(config)

      raise InvalidErrorMatcherError,
        "Invalid remappable error definition #{config}. Expected [error class, regex]."
    end

    def valid_config?(config)
      config.is_a?(Array) &&
        config[0] <= Exception &&
        config[1].is_a?(Regexp)
    end
  end
end
