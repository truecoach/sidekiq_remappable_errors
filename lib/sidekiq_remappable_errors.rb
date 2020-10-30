# frozen_string_literal: true

require "sidekiq_remappable_errors/version"
require "sidekiq_remappable_errors/errors"
require "sidekiq_remappable_errors/config"
require "sidekiq_remappable_errors/error_matcher"
require "sidekiq_remappable_errors/sidekiq_middleware"

module SidekiqRemappableErrors
  def self.included(klass)
    klass.extend(ClassMethods)
    klass.include(InstanceMethods)
    klass.initialize_remappable_errors
  end

  class << self
    def config
      @_config ||= Config.new
    end

    def configure
      yield(config)

      config.validate!
    end
  end

  module ClassMethods
    def initialize_remappable_errors
      define_singleton_method(:error_matchers_store) { [] }
      define_singleton_method(:remappable_errors_options_store) {
        { max_remaps: 5 }
      }
    end

    #
    # 2D array of error class + message regex. If a raised error
    # matches that class and it's error matches that regex the class
    # will be remapped.
    #
    # e.g.
    # remappable_errors [
    #   [ ActiveRecord::RecordNotFound, /trainer/i ],
    #   [ FlakyService::ServiceUnvailable, // ],
    # ]
    #
    def remappable_errors(errors)
      current_errors = error_matchers_store
      new_errors = errors.map { |error| ErrorMatcher.new(error) }

      define_singleton_method(:error_matchers_store) { current_errors + new_errors }
    end

    #
    # Define remapping behavior
    #
    # e.g. remappable_errors_options max_remaps: <<Integer>>
    #
    def remappable_errors_options(**opts)
      current_options = remappable_errors_options_store

      define_singleton_method(:remappable_errors_options_store) {
        current_options.merge(opts)
      }
    end
  end

  module InstanceMethods
    attr_writer :retry_count

    def retry_count
      @retry_count || 0
    end

    def remappable_retries_exhausted?
      retry_count >= [
        sidekiq_max_retries,
        self.class.remappable_errors_options_store[:max_remaps]
      ].min
    end

    private

    def with_remappable_errors
      yield
    rescue StandardError => e
      raise unless remappable_error?(e)
      raise if remappable_retries_exhausted?

      raise SidekiqRemappableErrors.config.remapped_error_class, e.inspect
    end

    def remappable_error?(error)
      self.class.error_matchers_store.any? do |remappable_error|
        remappable_error.match?(error)
      end
    end

    def sidekiq_max_retries
      @_sidekiq_max_retries ||= begin
        retry_opt = sidekiq_options[:retry]

        # 25 is the hardcoded default in Sidekiq
        return 0 if retry_opt == false
        return 25 if retry_opt == true

        retry_opt
      end
    end

    def sidekiq_options
      @_sidekiq_options ||= self.class.get_sidekiq_options.transform_keys(&:to_sym)
    end
  end
end
