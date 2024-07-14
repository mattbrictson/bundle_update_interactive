# frozen_string_literal: true

module BundleUpdateInteractive
  class OutdatedGem
    attr_accessor :name,
                  :gemfile_groups,
                  :git_source_uri,
                  :current_version,
                  :current_git_version,
                  :updated_version,
                  :updated_git_version

    attr_writer :rubygems_source, :vulnerable

    def initialize(**attrs)
      @vulnerable = nil
      @changelog_locator = ChangelogLocator.new

      attrs.each { |name, value| public_send(:"#{name}=", value) }
    end

    def semver_change
      @semver_change ||= SemverChange.new(current_version, updated_version)
    end

    def vulnerable?
      @vulnerable
    end

    def rubygems_source?
      @rubygems_source
    end

    def changelog_uri
      return @changelog_uri if defined?(@changelog_uri)

      @changelog_uri =
        if git_version_changed?
          "https://github.com/#{github_repo}/compare/#{current_git_version}...#{updated_git_version}"
        elsif rubygems_source?
          changelog_locator.find_changelog_uri(name: name, version: updated_version.to_s)
        else
          begin
            Gem::Specification.find_by_name(name)&.homepage
          rescue Gem::MissingSpecError
            nil
          end
        end
    end

    def git_version_changed?
      current_git_version && updated_git_version && current_git_version != updated_git_version
    end

    private

    attr_reader :changelog_locator

    def github_repo
      return nil unless updated_git_version

      git_source_uri.to_s[%r{^(?:git@github.com:|https://github.com/)([^/]+/[^/]+?)(:?\.git)?(?:$|/)}i, 1]
    end
  end
end
