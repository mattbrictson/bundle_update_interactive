# frozen_string_literal: true

require "shellwords"

module BundleUpdateInteractive
  class GitCommitter
    def initialize(updater)
      @updater = updater
    end

    def apply_updates_as_individual_commits(*gem_names)
      assert_git_executable!
      assert_working_directory_clean!

      gem_names.flatten.each do |name|
        updates = updater.apply_updates(name)
        updated_gem = updates[name] || updates.values.first
        next if updated_gem.nil?

        commit_message = format_commit_message(updated_gem)
        system "git add Gemfile Gemfile.lock", exception: true
        system "git commit -m #{commit_message.shellescape}", exception: true
      end
    end

    def format_commit_message(outdated_gem)
      [
        "Update",
        outdated_gem.name,
        outdated_gem.current_version.to_s,
        outdated_gem.current_git_version,
        "→",
        outdated_gem.updated_version.to_s,
        outdated_gem.updated_git_version
      ].compact.join(" ")
    end

    private

    attr_reader :updater

    def assert_git_executable!
      success = begin
        `git --version`
        Process.last_status.success?
      rescue SystemCallError
        false
      end
      raise Error, "git could not be executed" unless success
    end

    def assert_working_directory_clean!
      status = `git status --untracked-files=no --porcelain`.strip
      return if status.empty?

      raise Error, "`git status` reports uncommitted changes; please commit or stash them them first!\n#{status}"
    end
  end
end
