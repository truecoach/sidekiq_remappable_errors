require_relative 'lib/sidekiq_remappable_errors/version'

Gem::Specification.new do |spec|
  spec.name          = "sidekiq_remappable_errors"
  spec.version       = SidekiqRemappableErrors::VERSION
  spec.authors       = ["Adam Steel"]
  spec.email         = ["adamgsteel@gmail.com"]
  spec.summary       = %q{Configure error re-mapping behavior for Sidekiq jobs.}
  spec.description   = %q{
    This library is designed to reduce noise in your error reporting services,
    by remapping the classes of errors in Sidekiq jobs to a single, custom error,
    for a limited number of retries. You can then set up error handling rules
    specifically for your custom error, such as ignoring it completely.
  }
  spec.homepage      = "https://github.com/truecoach/sidekiq_remappable_errors"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency 'sidekiq'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'pry-doc'
  spec.add_development_dependency 'rubocop'
end
