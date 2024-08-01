# frozen_string_literal: true

require "json"

module BundleUpdateInteractive
  class ChangelogLocator
    GITHUB_PATTERN = %r{^(?:https?://)?github\.com/([^/]+/[^/]+)(?:\.git)?/?}.freeze
    URI_KEYS = %w[source_code_uri homepage_uri bug_tracker_uri wiki_uri].freeze
    FILE_PATTERN = /changelog|changes|history|news|release/i.freeze
    EXT_PATTERN = /md|txt|rdoc/i.freeze

    class GitHubRepo
      def self.from_uris(*uris)
        uris.flatten.each do |uri|
          return new(Regexp.last_match(1)) if uri&.match(GITHUB_PATTERN)
        end
        nil
      end

      attr_reader :path

      def initialize(path)
        @path = path
      end

      def discover_changelog_uri(version)
        repo_html = fetch_repo_html(follow_redirect: true)
        return if repo_html.nil?

        changelog_path = repo_html[%r{/(#{path}/blob/[^/]+/#{FILE_PATTERN}(?:\.#{EXT_PATTERN})?)"}i, 1]
        return "https://github.com/#{changelog_path}" if changelog_path

        releases_url = "https://github.com/#{path}/releases"
        releases_url if HTTP.head("#{releases_url}/tag/v#{version}").success?
      end

      private

      def fetch_repo_html(follow_redirect:)
        response = HTTP.get("https://github.com/#{path}")

        if response.code == "301" && follow_redirect
          @path = response["Location"][GITHUB_PATTERN, 1]
          return fetch_repo_html(follow_redirect: false)
        end

        response.success? ? response.body : nil
      end
    end

    def find_changelog_uri(name:, version: nil)
      data = fetch_rubygems_data(name, version)
      return if data.nil?

      if (rubygems_changelog_uri = data["changelog_uri"])
        rubygems_changelog_uri
      elsif (github_repo = GitHubRepo.from_uris(data.values_at(*URI_KEYS)))
        github_repo.discover_changelog_uri(data["version"])
      end
    end

    private

    def fetch_rubygems_data(name, version)
      api_url = if version.nil?
                  "https://rubygems.org/api/v1/gems/#{name}.json"
                else
                  "https://rubygems.org/api/v2/rubygems/#{name}/versions/#{version}.json"
                end

      response = HTTP.get(api_url)

      # Try again without the version in case the version does not exist at rubygems for some reason.
      # This can happen when using a pre-release Ruby that has a bundled gem newer than the published version.
      return fetch_rubygems_data(name, nil) if !response.success? && !version.nil?

      response.success? ? JSON.parse(response.body) : nil
    end
  end
end
