require_relative "lib/bundle_update_interactive/version"

Gem::Specification.new do |spec|
  spec.name = "bundle_update_interactive"
  spec.version = BundleUpdateInteractive::VERSION
  spec.authors = ["Matt Brictson"]
  spec.email = ["opensource@mattbrictson.com"]

  spec.summary = "TODO"
  spec.homepage = "https://github.com/mattbrictson/bundle_update_interactive"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1"

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
  spec.add_dependency "thor", "~> 1.2"
end
