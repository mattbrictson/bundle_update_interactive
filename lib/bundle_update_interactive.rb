# frozen_string_literal: true

module BundleUpdateInteractive
  autoload :BundlerCommands, "bundle_update_interactive/bundler_commands"
  autoload :ChangelogLocator, "bundle_update_interactive/changelog_locator"
  autoload :CLI, "bundle_update_interactive/cli"
  autoload :Gemfile, "bundle_update_interactive/gemfile"
  autoload :Lockfile, "bundle_update_interactive/lockfile"
  autoload :LockfileEntry, "bundle_update_interactive/lockfile_entry"
  autoload :OutdatedGem, "bundle_update_interactive/outdated_gem"
  autoload :Report, "bundle_update_interactive/report"
  autoload :SemverChange, "bundle_update_interactive/semver_change"
  autoload :VERSION, "bundle_update_interactive/version"
end
