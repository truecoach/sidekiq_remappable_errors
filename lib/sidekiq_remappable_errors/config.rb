# frozen_string_literal: true

module SidekiqRemappableErrors
  class Config
    def initialize(remapped_error_class: RemappedError)
      self.remapped_error_class = remapped_error_class
    end
    attr_accessor :remapped_error_class

    def validate!
      return true if remapped_error_class <= Exception

      raise InvalidConfigError, "'remapped_error_class' must be an Exception"
    end
  end
end
