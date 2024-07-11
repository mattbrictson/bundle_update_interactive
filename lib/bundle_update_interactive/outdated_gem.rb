# frozen_string_literal: true

module BundleUpdateInteractive
  class OutdatedGem
    attr_reader :current_lockfile_entry, :updated_lockfile_entry, :gemfile_groups
    attr_writer :vulnerable

    def initialize(current_lockfile_entry:, updated_lockfile_entry:, gemfile_groups:)
      @current_lockfile_entry = current_lockfile_entry
      @updated_lockfile_entry = updated_lockfile_entry
      @gemfile_groups = gemfile_groups
      @changelog_locator = ChangelogLocator.new
    end

    def name
      current_lockfile_entry.name
    end

    def semver_change
      @semver_change ||= SemverChange.new(current_version, updated_version)
    end

    def vulnerable?
      @vulnerable
    end

    def changelog_uri
      return @changelog_uri if defined?(@changelog_uri)

      @changelog_uri =
        if git_version_changed?
          "https://github.com/#{github_repo}/compare/#{current_git_version}...#{updated_git_version}"
        elsif updated_lockfile_entry.rubygems_source?
          changelog_locator.find_changelog_uri(name: name, version: updated_version.to_s)
        else
          begin
            Gem::Specification.find_by_name(name)&.homepage
          rescue Gem::MissingSpecError
            nil
          end
        end
    end

    def current_version
      current_lockfile_entry.version
    end

    def updated_version
      updated_lockfile_entry.version
    end

    def current_git_version
      current_lockfile_entry.git_version
    end

    def updated_git_version
      updated_lockfile_entry.git_version
    end

    def git_version_changed?
      current_git_version && updated_git_version && current_git_version != updated_git_version
    end

    private

    attr_reader :changelog_locator

    def github_repo
      return nil unless updated_git_version

      updated_lockfile_entry.git_source_uri.to_s[%r{^(?:git@github.com:|https://github.com/)([^/]+/[^/]+?)(:?\.git)?(?:$|/)}i,
                                                 1]
    end
  end
end
