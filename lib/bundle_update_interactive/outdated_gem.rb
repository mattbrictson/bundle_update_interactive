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

    attr_writer :changelog_uri, :rubygems_source, :vulnerable

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
        if (diff_url = build_git_diff_url)
          diff_url
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

    def build_git_diff_url
      return nil unless git_version_changed?

      if github_repo
        "https://github.com/#{github_repo}/compare/#{current_git_version}...#{updated_git_version}"
      elsif gitlab_repo
        "https://gitlab.com/os85/httpx/-/compare/#{current_git_version}...#{updated_git_version}"
      elsif bitbucket_cloud_repo
        "https://bitbucket.org/#{bitbucket_cloud_repo}/branches/compare/#{updated_git_version}..#{current_git_version}"
      end
    end

    def github_repo
      return nil unless updated_git_version

      git_source_uri.to_s[%r{^(?:git@github.com:|https://github.com/)([^/]+/[^/]+?)(:?\.git)?(?:$|/)}i, 1]
    end

    def gitlab_repo
      return nil unless updated_git_version

      git_source_uri.to_s[%r{^(?:git@gitlab.com:|https://gitlab.com/)([^/]+/[^/]+?)(:?\.git)?(?:$|/)}i, 1]
    end

    def bitbucket_cloud_repo
      return nil unless updated_git_version

      git_source_uri.to_s[%r{(?:@|://)bitbucket.org[:/]([^/]+/[^/]+?)(:?\.git)?(?:$|/)}i, 1]
    end
  end
end
