# frozen_string_literal: true

require_relative "lib/a_lox/version"

Gem::Specification.new do |spec|
  spec.name = "a_lox"
  spec.version = ALox::VERSION
  spec.authors = ["Svetlin Simonyan"]
  spec.email = ["svetlin.s@gmail.com"]

  spec.summary = "A Lox implementation"
  spec.description = "This a take on implementing (a subset of) the Lox language in Ruby"
  spec.homepage = "https://a-lox.svetlins.net"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/svetlins/a-lox"
  spec.metadata["changelog_uri"] = "https://github.com/svetlins/a-lox/blob/main/CHANGELOG.md"

  spec.files = Dir["CHANGELOG.md", "LICENSE.txt", "README.md", "lib/**/*", "sig/**/*"]

  spec.bindir = "exe"
  spec.executables = "alox"
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html
end
