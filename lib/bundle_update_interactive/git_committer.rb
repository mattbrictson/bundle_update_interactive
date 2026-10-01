# frozen_string_literal: true

module BundleUpdateInteractive
  class GitCommitter
    # Most to least severe. Advisories without a CVSS score report a nil criticality
    # and are sorted last.
    CRITICALITY_ORDER = %i[critical high medium low none].freeze

    def initialize(updater, advisories: {})
      @updater = updater
      @advisories = advisories
    end

    def apply_updates_as_individual_commits(*gem_names)
      assert_git_executable!
      assert_working_directory_clean!

      gem_names.flatten.each do |name|
        updates = updater.apply_updates(name)
        updated_gem = updates[name] || updates.values.first
        next if updated_gem.nil?

        system "git add Gemfile Gemfile.lock", exception: true
        system(*["git", "commit", *commit_message_args(name, updated_gem)], exception: true)
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

    def format_commit_body(name)
      advisories = advisories_for(name)
      return nil if advisories.empty?

      lines = ["Fixes known security vulnerabilities:", ""]
      sort_by_criticality(advisories).each do |advisory|
        criticality = advisory[:criticality]
        lines << "* #{"[#{criticality}] " if criticality}#{advisory[:title]}".rstrip
        lines << "  #{advisory[:url]}" if advisory[:url]
      end
      lines.join("\n")
    end

    private

    attr_reader :updater, :advisories

    def commit_message_args(name, updated_gem)
      subject = format_commit_message(updated_gem)
      body = format_commit_body(name)
      return ["-m", subject] if body.nil?

      ["-m", subject, "-m", body]
    end

    def advisories_for(name)
      Array(advisories[name])
    end

    # Stable sort: most severe first, preserving original order within the same criticality.
    def sort_by_criticality(advisories)
      advisories.each_with_index.sort_by do |advisory, index|
        [CRITICALITY_ORDER.index(advisory[:criticality]) || CRITICALITY_ORDER.length, index]
      end.map(&:first)
    end

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
