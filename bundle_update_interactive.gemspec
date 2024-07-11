# frozen_string_literal: true

require_relative "lib/bundle_update_interactive/version"

Gem::Specification.new do |spec|
  spec.name = "bundle_update_interactive"
  spec.version = BundleUpdateInteractive::VERSION
  spec.authors = ["Matt Brictson"]
  spec.email = ["opensource@mattbrictson.com"]

  spec.summary = "Adds a update-interactive command to Bundler"
  spec.homepage = "https://github.com/mattbrictson/bundle_update_interactive"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7"

  spec.metadata = {
    "bug_tracker_uri" => "https://github.com/mattbrictson/bundle_update_interactive/issues",
    "changelog_uri" => "https://github.com/mattbrictson/bundle_update_interactive/releases",
    "source_code_uri" => "https://github.com/mattbrictson/bundle_update_interactive",
    "homepage_uri" => spec.homepage,
    "rubygems_mfa_required" => "true"
  }

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.glob(%w[LICENSE.txt README.md {exe,lib}/**/*]).reject { |f| File.directory?(f) }
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "bundler", "~> 2.0"
  spec.add_dependency "bundler-audit", ">= 0.9.1"
  spec.add_dependency "faraday", ">= 2.8.0"
  spec.add_dependency "pastel", ">= 0.8.0"
  spec.add_dependency "thor", "~> 1.2"
  spec.add_dependency "tty-prompt", ">= 0.23.1"
  spec.add_dependency "tty-screen", ">= 0.8.2"
end
