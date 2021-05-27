[![Build Status](https://travis-ci.com/truecoach/sidekiq_remappable_errors.svg)](https://travis-ci.com/truecoach/sidekiq_remappable_errors)

# SidekiqRemappableErrors

`SidekiqRemappableErrors` was designed to solve the contradiction between error reporting and Sidekiq's raise-based retry mechanism. For many jobs, failing once or twice before succeeding is not only acceptable, it's common. This increases noise in error reporting services and logs.

When a raised error matches your criteria, `SidekiqRemappableErrors` will remap the error class to your predefined class which can easily be handled separately in your monitoring systems.

## Example

Define a job that will remap one error only on the first job failure.

```ruby
class ExampleError < StandardError; end

class ExampleJob
  include Sidekiq::Worker
  include SidekiqRemappableErrors

  remappable_errors_options max_remaps: 1
  remappable_errors [
    [ ExampleError, /test message/ ]
  ]

  def perform
    with_remappable_errors do
      raise ExampleError, 'test message'
    end
  end
end
```

Inspect logs to see remapping behavior

```bash
> ExampleJob.perform_async
# first failure
SidekiqRemappedError::RemappedError: #<ExampleError: test message>
# second failure
ExampleError: test message
```

## Installation

Add to your Gemfile

```ruby
gem 'sidekiq_remappable_errors'
```

Add the middleware

```ruby
Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add SidekiqRemappableErrors::SidekiqMiddleware
  end
end
```

Optional: Define your configuration. If using Rails, this could be done as an initializer.

```ruby
# config/initializers/sidekiq_remappable_errors.rb

SidekiqRemappableErrors.configure do |config|
  config.remapped_error_class = MyRemappedError
end
```

## Usage

### Options

*max_remaps*: maximum number of raises/retries you want the error to be remapped. After this count is exceeded the original error will be raised.

```
remappable_errors_options max_remaps: 1
```
