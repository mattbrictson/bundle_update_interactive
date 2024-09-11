# frozen_string_literal: true

require "delegate"
require "shellwords"

module BundleUpdateInteractive
  class GitCommittingUpdater < SimpleDelegator
    def apply_updates(selected_gems)
      selected_gems.each do |name, outdated_gem|
        updates = super(name => outdated_gem)
        commit_message = "Update #{name} gem from #{outdated_gem.current_version} to #{outdated_gem.updated_version}"
        commit_description = "Changelog: #{outdated_gem.changelog_uri}"
        system "git add Gemfile Gemfile.lock"
        system "git commit -m #{commit_message.shellescape} -m #{commit_description.shellescape}"
      end
    end
  end
end
